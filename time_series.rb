module CaptureTimeSeries
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def set_ts_options(options = {})
      class_attribute :ts_options
      self.ts_options = options.dup
      after_commit :after_create_callback, on: :create
      after_commit :after_update_callback, on: :update
      after_commit :after_destroy_callback, on: :destroy
    end
  end

  def after_create_callback
    model = ts_options[:ts_model]
    now = Time.now
    #Thread.new do
      begin
        model.transaction do
          if has_changes?
            close_last_ts_record(now)
            create_new_ts_record(now)
          end
        end
      rescue => e
        SellerCommon.logger.error "\n\n #{e.message}\n\n"
        SellerCommon.logger.error  "\n\n #{e.backtrace}\n\n"
      ensure
        SellerCommon.logger.info  "CaptureTimeSeries after_create_callback took #{Time.now - now} seconds"
        #ActiveRecord::Base.connection.close
      end
    #end
  end

  def after_update_callback
    model = ts_options[:ts_model]
    now = Time.now
    #Thread.new do
      begin
        model.transaction do
          if has_changes?
            close_last_ts_record(now)
            create_new_ts_record(now)
          end
        end
      rescue => e
        SellerCommon.logger.error "\n\n #{e.message}\n\n"
        SellerCommon.logger.error  "\n\n #{e.backtrace}\n\n"
      ensure
        SellerCommon.logger.info  "CaptureTimeSeries after_update_callback took #{Time.now - now} seconds"
        #ActiveRecord::Base.connection.close
      end
    #end
  end

  def after_destroy_callback
    model = ts_options[:ts_model]
    now = Time.now
    #Thread.new do
      begin
        close_last_ts_record(now)
      rescue => e
        SellerCommon.logger.error "\n\n #{e.message}\n\n"
        SellerCommon.logger.error  "\n\n #{e.backtrace}\n\n"
      ensure
        SellerCommon.logger.info  "CaptureTimeSeries into model: #{}after_destroy_callback took #{Time.now - now} seconds"
        #ActiveRecord::Base.connection.close
      end
    #end
  end

  private
  def close_last_ts_record(now)
    model = ts_options[:ts_model]
    unique_attrs = ts_options[:unique_attrs]
    q = model
    unique_attrs.each do |attr|
      q = q.where(attr => self[attr])
    end
    q = q.where(:end_time => nil)
    last_record = q.last
    if last_record.present?
      last_record[:end_time] = now
      last_record.save!
    end
  end

  def create_new_ts_record(now)
    model = ts_options[:ts_model]
    ignore_attrs = ts_options[:ignore_attrs]
    create_hash = Hash.new
    self_as_json = self.as_json
    #Removing the id attribute of the model to be tracked.
    self_as_json.delete("id")
    self_as_json.each do |key, value|
      key_as_symbol = key.to_sym
      if not ignore_attrs.include?(key_as_symbol)
        create_hash[key] = value
      end
    end
    create_hash[:start_time] = now
    create_hash[:end_time] = nil
    model.create(create_hash)
  end

  def has_changes?
    changes = self.previous_changes
    changed_attrs = changes.keys
    changed_attrs.map! { |x| x.to_sym }
    ignore_attrs = ts_options[:ignore_attrs]
    #Eliminating ignored attrs from changed_attrs
    changed_attrs = changed_attrs - ignore_attrs
    return changed_attrs.present?
  end
end
