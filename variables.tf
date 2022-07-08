variable "project" {
  type = string
  default = "917885277373"
}
variable "zone" {
  type = string
  default = "europe-west3-a"
}
variable "region" {
  type = string
  default = "europe-west3"
}

variable "machine_type" {
  type = string
  default = "e2-standard-2"
}
variable "image" {
  type = string
  default = "ubuntu-2004-focal-v20220606"
}
variable "firewall" {
  type = list
  default = ["80", "8080", "3000-3010", "9000-10000", "30000-32767", "22"]
}
