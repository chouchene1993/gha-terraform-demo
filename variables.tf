variable "private_endpoint_ip_parameters" {

description = "Private endpoint IP configuarations"
type        = map(string)
default     = {
    subnet_id = null 
    group_id  = null
}
}
