variable "name" {
  type = string
}

variable "node" {
  type = string
}

variable "clone" {
  type = string
}

variable "cores" {
  type = number
  default = 1
}

variable "sockets" {
  type = number
  default = 1
}

variable "memory" {
  type = number
  default = 512
}

variable "disk_gb" {
  type = number
  default = 4
}

variable "ip" {
  type = string
}

variable "gateway" {
  type = string
}
