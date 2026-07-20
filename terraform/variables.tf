variable "splunk_token" {
  description = "The Splunk HEC Token for Lambda authentication"
  type        = string
  sensitive   = true
}

variable "splunk_hec_url" {
  description = "The URL for the Splunk HEC endpoint"
  type        = string
}