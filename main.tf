resource "random_pet" "random" {
  length = 5
}

output "a" {
  value = random_pet.random
}
