# time_series
A ActiveRecord Plugin to record time series data for a given Model.

# Using it:

1) Create a model where you want to store the time_Series data and point it to ts_model.
2) Include this configuration on any activerecord model:
```
include CaptureTimeSeries
set_ts_options({
  :ignore_attrs => [:deleted_at, :created_at, :updated_at],
  :ts_model => InventoryUpdate,
  :unique_attrs => [:store_id, :variant_id, :barcode]
})
```
