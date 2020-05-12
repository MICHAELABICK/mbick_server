# Vault Authentication
Before Terraform can be run,
we must first authenticate to Hashicorp Vault.
Inside the project `src` directory, run,

``` sh
	./scripts/vault-login
	vault -login -method=userpass -address=<address> username=<username>
```

Once that is done, `cd` to the desired Terraform directory.
Then run Terraform as you would like using the helper script,

``` sh
	cd terraform/kube-dev
	../scripts/mbick-tf init
	../scripts/mbick-tf plan
	../scripts/mbick-tf apply
```
