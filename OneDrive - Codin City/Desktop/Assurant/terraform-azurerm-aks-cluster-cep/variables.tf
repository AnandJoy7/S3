variable "rg_name" {
  type        = string
  description = "Resource Group Name"
}

variable "location" {
  type        = string
  description = "Cluster Location"
}

variable "aks_cluster" {
  description = <<-EOF
  Objects for the AKS cluster.

  Available options:
  - `cluster_name`              = (Required|string) Cluster Name.
  - `automatic_channel_upgrade` = (Required|string) The upgrade channel for this Kubernetes Cluster. Possible values are patch, rapid, node-image and stable. Defaults to none.
  - `kubernetes_version`        = (Optional|string) Kubernetes version to deploy.
  - `local_account_disabled`    = (Optional|string) Disable local account for node authentication. Default to false.
  - `zones`                     = (Optional|string) Availability Zones. Default to ["1", "2", "3"].
  - `log_analytics_workspace_id`= (Required|string) "Log Analytics workspace resource id"

  Example:
  ```
  aks_cluster = ({    
    cluster_name                = "testing"
    kubernetes_version          = "1.28.5"
    automatic_channel_upgrade   = "patch"
    local_account_disabled      = false
    zones                       = ["1", "2", "3"]
    log_analytics_workspace_id  = "log-workspace"
  })
  ```
  EOF

  type = object({
    cluster_name               = string
    automatic_channel_upgrade  = string
    kubernetes_version         = optional(string, "1.28.5")
    local_account_disabled     = optional(bool, false)
    zones                      = optional(list(string), ["1", "2", "3"])
    log_analytics_workspace_id = string
  })

  validation {
    condition     = contains(["patch", "rapid", "node-image", "stable", "none"], lower(var.aks_cluster.automatic_channel_upgrade))
    error_message = "The value must be a valid string. patch, rapid, node-image or stable. Defaults to none."
  }
}

variable "create_groups" {
  type        = bool
  description = "Create RBAC Groups"
  default     = false
}

variable "rbac_aad_admin_group_object_ids" {
  description = "Object ID of groups with admin access."
  type        = list(string)
  default     = []
}

variable "network_settings" {
  description = <<-EOF
  Objects for the AKS cluster network Settings.

  Available options:
  - `network_plugin`        = (optional|string) Network plugin to use. Options: kubenet or azure (default).
  - `dns_service_ip`        = (optional|string) DNS Service IP (typically in var.service_cidr ending in .10).
  - `pod_cidr`              = (optional|string) Pod  CIDR range. if `network_plugin` = "kubenet", then pod cidr range is required.
  - `service_cidr`          = (optional|string) Service  CIDR range.
  - `appgw_subnet_id`       = (optional|string) Application Gateway Subnet ID. Specifying this creates an application gateway.
  - `application_gateway_id`= (optional|string) The ID of the Application Gateway to integrate with the ingress controller of this Kubernetes Cluster. See this page for further details.

  Example:
  ```
  network_settings = ({    
    network_plugin       = "azure"
    pod_cidr             = null
  })
  ```
  EOF

  type = object({
    network_plugin         = optional(string, "azure")
    dns_service_ip         = optional(string, "192.168.0.10")
    pod_cidr               = optional(string, null)
    service_cidr           = optional(string, "192.168.0.0/16")
    appgw_subnet_id        = optional(string, "")
    application_gateway_id = optional(string, "")
  })

  validation {
    condition     = contains(["azure", "kubenet"], lower(var.network_settings.network_plugin))
    error_message = "Currently supported values are azure and kubenet. Defaults to azure."
  }

  validation {
    condition     = var.network_settings.network_plugin == "kubenet" ? var.network_settings.pod_cidr != null : true
    error_message = "Error: Required the input for Pod Cidr as it is defined to value null"
  }

  validation {
    condition     = var.network_settings.appgw_subnet_id == "" || var.network_settings.application_gateway_id == ""
    error_message = "Error: Exactly one of `appgw_subnet_id` or `application_gateway_id` must be specified."
  }
}

variable "default_node_pool" {
  description = <<-EOF
  Objects for the AKS cluster default Node Pools.

  Available options:
  - `name`                          = The name of the Node Pool which should be created within the Kubernetes Cluster. 
  - `vm_size `                      = The SKU which should be used for the Virtual Machines used in this Node Pool. Default to Standard_DS4_v2.
  - `vm_type`                       = The type of Default Node Pool for the Kubernetes Cluster must be VirtualMachineScaleSets to attach multiple node pools. Default to VirtualMachineScaleSets.
  - `os_disk_size_gb`               = The Agent Operating System disk size in GB.
  - `subnet_id`                     = The ID of the Subnet where this Node Pool should exist.
  - `pod_subnet_id`                 = The ID of the Subnet where the pods in the default Node Pool should exist.
  - `enable_autoscaling`            =  Whether to enable auto-scaler. Default to false.
  - `max_pods`                      = The maximum number of pods that can run on each agent. Default to 30.
  - `node_count`                    = The number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 (inclusive) for user pools and between 1 and 1000 (inclusive) for system pools. Default to 3.
  - `autoscaling_min_nodes`         = The minimum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be less than or equal to max_count. Default to null.
  - `autoscaling_max_nodes`         = The maximum number of nodes which should exist within this Node Pool. Valid values are between 0 and 1000 and must be greater than or equal to min_count. Default to 1.
  - `kube_node_labels`              = A map of Kubernetes labels which should be applied to nodes in this Node Pool.
  - `only_critical_addons_enabled`  = Enabling this option will taint default node pool with CriticalAddonsOnly=true:NoSchedule taint. Default to true.
  - 'temporary_name_for_rotation'   = When updating above paraemters, temporary_name_for_rotation must be specified fo the rotation
  EOF

  type = object({
    name                         = optional(string, "default")
    node_count                   = optional(number, 3)
    vm_size                      = optional(string, "Standard_DS3_v2")
    vm_type                      = optional(string, "VirtualMachineScaleSets")
    os_disk_size_gb              = optional(number, 32)
    subnet_id                    = string
    pod_subnet_id                = optional(string, null)
    enable_autoscaling           = optional(bool, false)
    max_pods                     = optional(number, 30)
    autoscaling_min_nodes        = optional(number, 1)
    autoscaling_max_nodes        = optional(number, null)
    kube_node_labels             = optional(map(string), {})
    only_critical_addons_enabled = optional(bool, true)
    temporary_name_for_rotation  = optional(string, null)
  })
}

variable "key_vault_secrets_provider_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether to use the Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster. For more details: https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver"
}

variable "key_vault_secrets_provider" {
  description = <<EOF
  (Optional) Whether to use the Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster. For more details: https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver

  Available options: 
    - `secret_rotation_enabled`  = (Optional|bool) Is secret rotation enabled? This variable is only used when `key_vault_secrets_provider_enabled` is `true` and defaults to `false`. 
    - `secret_rotation_interval`  = (Optional|string) The interval to poll for secret rotation. This attribute is only set when `secret_rotation` is `true` and defaults to `2m`.

  Example:
  ```
  key_vault_secrets_provider = {
    secret_rotation_enabled = true
    secret_rotation_interval = "2m"
  }
  
  ```
  EOF
  type = object({
    secret_rotation_enabled  = optional(bool, false)
    secret_rotation_interval = optional(string, "2m")
  })
}

variable "auto_scaler_profile_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Enable or Disable Autoscaler profile. Defaults to false"
}

variable "auto_scaler_profile" {
  description = <<EOF
  (Optional) Workload Autoscaler Profile in an AKS cluster.

  Available options: 
    - `balance_similar_node_groups`  = (Optional|bool) Detect similar node groups and balance the number of nodes between them. Defaults to `false`.
    - `empty_bulk_delete_max`  = (Optional|number) Maximum number of empty nodes that can be deleted at the same time. Defaults to `10`.
    - `expander`  = (Optional|string) Expander to use. Possible values are `least-waste`, `priority`, `most-pods` and `random`. Defaults to `random`.
    - `max_graceful_termination_sec`  = (Optional|string) Maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node. Defaults to `600`.
    - `max_node_provisioning_time`  = (Optional|string) Maximum time the autoscaler waits for a node to be provisioned. Defaults to `15m`.
    - `max_unready_nodes`  = (Optional|number) Maximum Number of allowed unready nodes. Defaults to `3`.
    - `max_unready_percentage`  = (Optional|number) Maximum percentage of unready nodes the cluster autoscaler will stop if the percentage is exceeded. Defaults to `45`.
    - `new_pod_scale_up_delay`  = (Optional|string) For scenarios like burst/batch scale where you don't want CA to act before the kubernetes scheduler could schedule all the pods, you can tell CA to ignore unscheduled pods before they're a certain age. Defaults to `10s`.
    - `scale_down_delay_after_delete`  = (Optional|string) How long after node deletion that scale down evaluation resumes. Defaults to the value used for `scan_interval`.
    - `scale_down_delay_after_failure`  = (Optional|string) How long after scale down failure that scale down evaluation resumes. Defaults to `3m`.
    - `scale_down_unneeded`  = (Optional|string) How long a node should be unneeded before it is eligible for scale down. Defaults to `10m`.
    - `scale_down_unready`  = (Optional|string) How long an unready node should be unneeded before it is eligible for scale down. Defaults to `20m`.
    - `scale_down_utilization_threshold`  = (Optional|string) Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down. Defaults to `0.5`.
    - `scan_interval`  = (Optional|string) How often the AKS Cluster should be re-evaluated for scale up/down. Defaults to `10s`.
    - `skip_nodes_with_local_storage`  = (Optional|bool) If `true` cluster autoscaler will never delete nodes with pods with local storage, for example, EmptyDir or HostPath. Defaults to `true`.
    - `skip_nodes_with_system_pods`  = (Optional|bool) If `true` cluster autoscaler will never delete nodes with pods from kube-system (except for DaemonSet or mirror pods). Defaults to `true`.
                              
  Example:
  ```
  auto_scaler_profile = {
    balance_similar_node_groups = false
    empty_bulk_delete_max = 10
    expander = "random"
    max_graceful_termination_sec = "600"
    max_node_provisioning_time = "15m"
    max_unready_nodes = 3
    max_unready_percentage = 45
    new_pod_scale_up_delay = "10s"
    scale_down_delay_after_delete = null
    scale_down_delay_after_failure = "3m"
    scale_down_unneeded = "10m"
    scale_down_unready = "20m"
    scale_down_utilization_threshold = "0.5"
    scan_interval = "10s"
    skip_nodes_with_local_storage = true
    skip_nodes_with_system_pods = true                              
  }
  
  ```
  EOF
  type = object({
    balance_similar_node_groups      = optional(bool, false)
    empty_bulk_delete_max            = optional(number, 10)
    expander                         = optional(string, "random")
    max_graceful_termination_sec     = optional(string, "600")
    max_node_provisioning_time       = optional(string, "15m")
    max_unready_nodes                = optional(number, 3)
    max_unready_percentage           = optional(number, 45)
    new_pod_scale_up_delay           = optional(string, "10s")
    scale_down_delay_after_delete    = optional(string, null)
    scale_down_delay_after_failure   = optional(string, "3m")
    scale_down_unneeded              = optional(string, "10m")
    scale_down_unready               = optional(string, "20m")
    scale_down_utilization_threshold = optional(string, "0.5")
    scan_interval                    = optional(string, "10s")
    skip_nodes_with_local_storage    = optional(bool, true)
    skip_nodes_with_system_pods      = optional(bool, true)
  })
  default = null
}

variable "workload_autoscaler_profile_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Enable or Disable Workload Autoscaler profile. Defaults to false"
}

variable "workload_autoscaler_profile" {
  description = <<EOF
  (Optional) Workload Autoscaler Profile in an AKS cluster.

  Available options: 
    - `keda_enabled`  = (Optional|bool) Specifies whether KEDA Autoscaler can be used for workloads.
    - `vertical_pod_autoscaler_enabled`  = (Optional|bool) Specifies whether Vertical Pod Autoscaler should be enabled.

  Example:
  ```
  workload_autoscaler_profile = {
    keda_enabled = true
    vertical_pod_autoscaler_enabled = false
  }
  
  ```
  EOF
  type = object({
    keda_enabled                    = optional(bool, false)
    vertical_pod_autoscaler_enabled = optional(bool, false)
  })
}

variable "default_tags" {
  type        = map(string)
  description = "A map of standard tags"
  default     = {}
}

variable "tags" {
  type        = map(any)
  description = "Azure Tags"
  default     = {}
}

# maintenance window config variables for both maintenance_windows_auto_upgrade and maintenance_window_maintenance_window_node_os 
variable "maintenance_window_auto_upgrade" {
  description = "(Optional)"
  type = optional(object({
    frequency    = string # Possible values: Weekly, AbsoluteMonthly, RelativeMonthly
    interval     = number # Possible values should be greater than 0
    duration     = number # Possible values are 4-24
    day_of_week  = optional(string) # Possible values: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    day_of_month = optional(number) # Possible values: 0-31
    week_index   = optional(string) # Possible values: First, Second, Third, Fourth, Last
    start_time   = optional(string) # Possible values are 12:45, 23:59, 05:30 with HH:mm format
    utc_offset   = optional(string) # Possible values are -12:00, -11:00, -10:00, 
    start_date   = optional(string) # Possible values are 2022-01-01, 2022-01-01T
    not_allowed = optional(list(Object({ 
      start = string 
      end   = string
    })))
    default = null
  }))

  validation {
    condition     = contains(["Weekly", "AbsoluteMonthly", "RelativeMonthly"].var.maintenance_window_auto_upgrade.frequency)
    error_message = "Frequency must be one of: Weekly, AbsoluteMonthly, or RelativeMonthly."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.interval > 0
    error_message = "interval must be a positive number."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.duration >= 4 && var.maintenance_window_auto_upgrade.duration <= 24
    error_message = "Duration must be between 4 and 24 hours."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.frequency != "Weekly" || contains(["Friday", "Monday", "Saturday", "Sunday", "Thursday", "Tuesday", "Wednesday"], var.maintenance_window_auto_upgrade.day_of_week)
    error_message = "When frequency is Weekly, day_of_week must be a valid day of the week."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.frequency != "AbsoluteMonthly" || (var.maintenance_window_auto_upgrade.day_of_month >= 0 && var.maintenance_window_auto_upgrade.day_of_month <= 31)
    error_message = "When frequency is AbsoluteMonthly, day_of_month must be between 0 and 31."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.frequency != "RelativeMonthly" || contains(["First", "Second", "Third", "Fourth", "Last"], var.maintenance_window_auto_upgrade.week_index)
    error_message = "When frequency is RelativeMonthly, week_index must be one of: First, Second, Third, Fourth, or Last."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.start_time == null || can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", var.maintenance_window_auto_upgrade.start_time))
    error_message = "start_time must be in HH:mm format."
  }
  validation {
    condition     = var.maintenance_window_auto_upgrade.utc_offset == null || can(regex("^UTC[+-](0[0-9]|1[0-4]):[0-5][0-9]$", var.maintenance_window_auto_upgrade.utc_offset))
    error_message = "utc_offset must be in the format UTC±HH:MM (e.g., UTC+05:30 or UTC-08:00)."
  }

  validation {
    condition     = var.maintenance_window_auto_upgrade.start_date == null || can(regex("^(\\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$", var.maintenance_window_auto_upgrade.start_date))
    error_message = "start_date must be in YYYY-MM-DD format (e.g., 2024-06-15)."
  }

  validation {
    condition = var.maintenance_window_auto_upgrade.not_allowed == null || alltrue([
      for na in var.maintenance_window_auto_upgrade.not_allowed : can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", na.start)) && can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", na.end))
    ])
    error_message = "Each not_allowed entry must have start and end times in HH:mm format."
  }
}

#maitenace_window variable and validation for allowed & not allowed
variable "maintenance_window" {
  description = "(Optional) Defines the maintenance window settings, including allowed and not allowed time spans."
  type = optional(object({
    allowed = optional(list(object({
      day   = string      # Possible values are Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday 
      hours = set(number) # Possible values are 0-23
    })), [])

    not_allowed = optional(list(object({
      start = string # 2023-06-15T08:15:00Z 
      end   = string # 2024-02-04T14:30:45Z in YYYY-MM-DDTHH:MM:SSZ format
    })), [])
  }), {})

  validation {
    condition = var.maintenance_window == null || alltrue([
      for allowed_slot in var.maintenance_window.allowed :
      contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], allowed_slot.day) &&
      alltrue([for h in allowed_slot.hours : h >= 0 && h <= 23])
    ])
    error_message = "Each allowed day must be a valid day of the week (Sunday-Saturday), and all hours must be between 0 and 23."
  }

  validation {
    condition = (
      var.maintenance_window == null || length(var.maintenance_window.not_allowed) == 0 ||
      alltrue([
        for not_allowed_slot in var.maintenance_window.not_allowed :
        can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", not_allowed_slot.start)) &&
        can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", not_allowed_slot.end)) &&
        not_allowed_slot.start < not_allowed_slot.end
      ])
    )
    error_message = "Each not_allowed block must have valid RFC3339 timestamps (YYYY-MM-DDTHH:MM:SSZ), and 'start' must be before 'end'."
  }

}

variable "node_os_channel_upgrade" {
  description = "(Optional) Possible values are Unmanaged, SecurityPatch, NodeImage, and None."
  type        = string
  default     = null

  validation {
    condition     = var.node_os_channel_upgrade == null || contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], var.maintenance_window_node_os_upgrade_channel)
    error_message = "node_os_channel_upgrade must be one of: Unmanaged, SecurityPatch, NodeImage, or None. Defaults to NodeImage if not set."
  }
}

# maintence window node os
variable "maintenance_window_node_os" {
  description = "Configuration for Node OS maintenance window"
  type = object({
    frequency    = string # Possible values: Weekly, AbsoluteMonthly, RelativeMonthly
    interval     = number # Must be > 0
    duration     = number # Must be between 4-24 hours
    day_of_week  = optional(string) # weekly frequency (Monday - Sunday)
    day_of_month = optional(number) # AbsoluteMonthly frequency (0-31)
    week_index   = optional(string) # for RelativeMonthly (First, Second, etc.)
    start_time   = optional(string) # HH:mm format
    utc_offset   = optional(string) # UTC±HH:MM format
    start_date   = optional(string) # YYYY-MM-DD format
    not_allowed  = optional(list(object({
      start = string # Start time (HH:mm format)
      end   = string # End time (HH:mm format)
    })))
  })

  validation {
    condition     = contains(["Weekly", "AbsoluteMonthly", "RelativeMonthly"], var.maintenance_window_node_os.frequency)
    error_message = "Frequency must be one of: Weekly, AbsoluteMonthly, or RelativeMonthly."
  }

  validation {
    condition     = var.maintenance_window_node_os.interval > 0
    error_message = "Interval must be a positive number."
  }

  validation {
    condition     = var.maintenance_window_node_os.duration >= 4 && var.maintenance_window_node_os.duration <= 24
    error_message = "Duration must be between 4 and 24 hours."
  }

  validation {
    condition     = var.maintenance_window_node_os.frequency != "Weekly" || contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], var.maintenance_window_node_os.day_of_week)
    error_message = "When frequency is Weekly, day_of_week must be a valid day of the week."
  }

  validation {
    condition     = var.maintenance_window_node_os.frequency != "AbsoluteMonthly" || (var.maintenance_window_node_os.day_of_month >= 0 && var.maintenance_window_node_os.day_of_month <= 31)
    error_message = "When frequency is AbsoluteMonthly, day_of_month must be between 1 and 31."
  }

  validation {
    condition     = var.maintenance_window_node_os.frequency != "RelativeMonthly" || contains(["First", "Second", "Third", "Fourth", "Last"], var.maintenance_window_node_os.week_index)
    error_message = "When frequency is RelativeMonthly, week_index must be one of: First, Second, Third, Fourth, or Last."
  }

  validation {
    condition     = var.maintenance_window_node_os.start_time == null || can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", var.maintenance_window_node_os.start_time))
    error_message = "start_time must be in HH:mm format."
  }

  validation {
    condition     = var.maintenance_window_node_os.utc_offset == null || can(regex("^UTC[+-](0[0-9]|1[0-4]):[0-5][0-9]$", var.maintenance_window_node_os.utc_offset))
    error_message = "utc_offset must be in UTC±HH:MM format (e.g., UTC+05:30 or UTC-08:00)."
  }

  validation {
    condition     = var.maintenance_window_node_os.start_date == null || can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.maintenance_window_node_os.start_date))
    error_message = "start_date must be in YYYY-MM-DD format."
  }

  validation {
    condition = var.maintenance_window_node_os.not_allowed == null || alltrue([ 
      for na in var.maintenance_window_node_os.not_allowed : can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", na.start)) && can(regex("^(?:[01]\\d|2[0-3]):[0-5]\\d$", na.end))
    ])
    error_message = "Each not_allowed entry must have start and end times in HH:mm format."
  }
}

