# Environment
Before many Terraform commands can be run, we need to source the environment variables that Terraform will use. This can be easily done with our helper script,

``` bash
    cd docker-dev
    source ../scripts/set-terraform-environment
```

Once that is done, run Terraform as you would like,

``` sh
    terraform init
    terraform plan
    terraform apply
```
