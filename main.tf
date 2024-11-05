resource "null_resource" "cluster" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "chmod +x backscript.sh ; ./backscript.sh"
  }
}
