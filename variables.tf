variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true # terraform plan/apply の出力にパスワードが表示されなくなる
}
