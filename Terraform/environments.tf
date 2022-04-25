locals {
  environments = {
    #Add here as many environments you may need
    "dev" = {
      # Add here specific environment configuration
      app_service_plan = {
        os_type  = "Linux"
        sku_name = "S1"
      }
    }
    # "qa" = {
    #   os_type  = "Linux"
    #   sku_name = "P1v2"
    # }
  }
}