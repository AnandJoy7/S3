package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformMain(t *testing.T) {
	t.Parallel()

	//Tags to be checked
	expectedTags := [4]string{"App_Name", "App_Owner", "Cost_Center", "subCost_Center"}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "./",
	}
	defer terraform.Destroy(t, terraformOptions)
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Retrieve the terraform output and set them to a variable
	aksTags := terraform.OutputMapOfObjects(t, terraformOptions, "aks_tags")

	//Test Functions to run
	CheckTags(t, aksTags, expectedTags)
}

func CheckExpectedTagsInArray(expectedTag string, actualTag map[string]interface{}) bool {
	for key := range actualTag {
		if key == expectedTag {
			return true
		}
	}
	return false
}

func CheckTags(t *testing.T, tags map[string]interface{}, expectedTags [4]string) {
	// Loop the expected tags array and check to see if they exist in the resource group
	for _, value := range expectedTags {
		fmt.Println("Checkingtag: " + value)
		foundtag := CheckExpectedTagsInArray(value, tags)
		assert.True(t, foundtag, "Expected tag "+value+" was not present")
	}
}
