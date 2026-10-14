options(
  AD_MAV_DATA_DIR = Sys.getenv("AD_MAV_DATA_DIR", unset = ""),
  AD_MAV_OUTPUT_DIR = Sys.getenv("AD_MAV_OUTPUT_DIR", unset = "results"),
  AD_MAV_BOOTSTRAP_B = as.integer(Sys.getenv("AD_MAV_BOOTSTRAP_B", unset = "500")),
  AD_MAV_SEED = as.integer(Sys.getenv("AD_MAV_SEED", unset = "20260914"))
)
