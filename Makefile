build: fmt
	packer build alpine.pkr.hcl	
fmt:
	packer fmt -recursive .
