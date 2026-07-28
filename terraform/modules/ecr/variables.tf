variable "repository_names" {
  description = "Names of ECR repositories to create"
  type        = list(string)
  default     = ["merchant-api"]
}

variable "image_expiration_days" {
  description = "Days after which to expire untagged images"
  type        = number
  default     = 30
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten after push. IMMUTABLE prevents an existing tag (e.g. a git SHA or semver) from being silently replaced."
  type        = string
  default     = "IMMUTABLE"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
