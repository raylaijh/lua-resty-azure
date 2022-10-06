package main

import (
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

var Tokens map[string]int64 = map[string]int64{}

var letterRunes = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
var serverAddress string = "0.0.0.0:8081"

type AzureErrorDetail struct {
	Code    string `json:"code"`
	Message string `json:"Message"`
}

type AzureError struct {
	Error *AzureErrorDetail `json:"error"`
}

func RandStringRunes(length int) string {
	b := make([]rune, length)
	for i := range b {
		b[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return string(b)
}

func main() {
	rand.Seed(time.Now().UnixNano())

	r := mux.NewRouter()
	r.HandleFunc("/{tenantId}/oauth2/v2.0/token", OAuthTokenPost).Methods("POST")
	r.HandleFunc("/keyvault/{vaultName}/secrets/{secretName}", KeyVaultGetSecretDefault).Methods("GET")
	r.HandleFunc("/keyvault/{vaultName}/secrets/{secretName}/{secretVersion}", KeyVaultGetSecretVersion).Methods("GET")
	r.HandleFunc("/keyvault/{vaultName}/certificates/{certificateName}", KeyVaultGetCertificateDefault).Methods("GET")
	r.HandleFunc("/keyvault/{vaultName}/certificates/{certificateName}/{certificateVersion}", KeyVaultGetCertificateVersion).Methods("GET")
	r.HandleFunc("/keyvault/{vaultName}/keys/{keyName}", KeyVaultGetKeyDefault).Methods("GET")
	r.HandleFunc("/keyvault/{vaultName}/keys/{keyName}/{keyVersion}", KeyVaultGetKeyVersion).Methods("GET")
	r.HandleFunc("/metadata/identity/oauth2/token", InstanceMetadataTokenGet).Methods("GET")

	log.Printf("Starting fakeazure server on %s\n", serverAddress)
	http.ListenAndServe(serverAddress, r)
}
