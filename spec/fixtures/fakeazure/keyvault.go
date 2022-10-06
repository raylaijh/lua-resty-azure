package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

type KeyVaultAttributes struct {
	Created         int64  `json:"created"`
	Enabled         bool   `json:"enabled"`
	Expiry          int64  `json:"exp"`
	RecoverableDays int32  `json:"recoverableDays"`
	RecoveryLevel   string `json:"recoveryLevel"`
	Updated         int64  `json:"updated"`
}

type KeyVaultGetSecretResponse struct {
	Attributes *KeyVaultAttributes `json:"attributes"`
	ID         string              `json:"id"`
	Tags       map[string]string   `json:"tags"`
	Value      string              `json:"value"`
}

func KeyVaultGetKeyVersion(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	keyVersion := vars["keyVersion"]

	KeyVaultGetKey(w, r, keyVersion)
}

func KeyVaultGetKeyDefault(w http.ResponseWriter, r *http.Request) {
	KeyVaultGetKey(w, r, "9bdcdbefc49446dd9a2a9b3f55e10340")
}

func KeyVaultGetKey(w http.ResponseWriter, r *http.Request, keyVersion string) {
	vars := mux.Vars(r)
	keyName, ok := vars["keyName"]
	if !ok {
		log.Println("Not keyName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}
	vaultName, ok := vars["vaultName"]
	if !ok {
		log.Println("Not vaultName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}

	// Check if we want a fake error
	var withCode int = 0
	var err error

	withCodeRaw := r.URL.Query().Get("withcode")
	if withCodeRaw != "" {
		withCode, err = strconv.Atoi(withCodeRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error": map[string]string{
					"code":    "internal server error",
					"message": "could not parse 'withcode' as an integer when retrieving key",
				},
			})

			return
		}
	}

	switch withCode {
	case 500:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "internal server error",
				"message": "error retrieving key",
			},
		})

		return

	case 501:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("<html><body>This is some HTML error that can happen</body></html>"))

		return

	case 502:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"fault": map[string]string{
				"msg": "good json syntax but badly formatted error message",
			},
		})

		return

	case 401:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(401)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "unauthorized",
				"message": "invalid authentication credentials when retrieving key",
			},
		})

		return

	case 404:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(404)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "KeyNotFound",
				"message": fmt.Sprintf("A key with (name/id) %s was not found in this key vault. If you recently deleted this key you may be able to recover it using the correct recovery command. For help resolving this issue, please see redacted", keyName),
			},
		})

		return

	case 403:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(403)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "forbidden",
				"message": "not allowed on this specific tenant perhaps when retrieving key",
			},
		})

		return

	default:
		if withCode == 0 || withCode == 200 {
			authHeader := r.Header.Get("Authorization")

			//if contains(Tokens, authHeader) {
			if expiresAt, ok := Tokens[authHeader]; ok {
				if time.Now().Unix() > expiresAt {
					// Unauthorized
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusUnauthorized)
					json.NewEncoder(w).Encode(AzureError{
						&AzureErrorDetail{
							Code:    "Unauthorized",
							Message: "[TokenExpired] Error validating token: 'S2S12086'.",
						},
					})
				} else {
					// Good
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusOK)

					keyObject := &AzureKey{}
					json.Unmarshal([]byte(`{    "attributes": {        "created": 1673029410,        "enabled": true,        "recoverableDays": 7,        "recoveryLevel": "CustomizedRecoverable+Purgeable",        "updated": 1673029410    },    "key": {        "e": "AQAB",        "key_ops": [            "sign",            "verify",            "wrapKey",            "unwrapKey",            "encrypt",            "decrypt"        ],        "kid": "https://localhost",        "kty": "RSA",        "n": "ruqZAvsEEnCJqpNmVZbi...=="    },    "tags": {}}`), keyObject)

					keyObject.Key.Kid = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/keys/%s/%s", vaultName, keyName, keyVersion)

					json.NewEncoder(w).Encode(keyObject)
				}
			} else {
				// Unauthorized
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				json.NewEncoder(w).Encode(AzureError{
					&AzureErrorDetail{
						Code:    "Unauthorized",
						Message: "[BearerReadAccessTokenFailed] Error validating token: 'S2S12005'.",
					},
				})
			}

		} else {
			// Nonspecific fake error code
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(withCode)
			json.NewEncoder(w).Encode(map[string]string{
				"nonspecific error": "error retrieving secret",
			})

		}
	}
}

func KeyVaultGetCertificateVersion(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	certificateVersion := vars["certificateVersion"]

	KeyVaultGetCertificate(w, r, certificateVersion)
}

func KeyVaultGetCertificateDefault(w http.ResponseWriter, r *http.Request) {
	KeyVaultGetCertificate(w, r, "9bdcdbefc49446dd9a2a9b3f55e10340")
}

func KeyVaultGetCertificate(w http.ResponseWriter, r *http.Request, certificateVersion string) {
	vars := mux.Vars(r)
	certificateName, ok := vars["certificateName"]
	if !ok {
		log.Println("Not certificateName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}
	vaultName, ok := vars["vaultName"]
	if !ok {
		log.Println("Not vaultName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}

	// Check if we want a fake error
	var withCode int = 0
	var err error

	withCodeRaw := r.URL.Query().Get("withcode")
	if withCodeRaw != "" {
		withCode, err = strconv.Atoi(withCodeRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error": map[string]string{
					"code":    "internal server error",
					"message": "could not parse 'withcode' as an integer when retrieving secret",
				},
			})

			return
		}
	}

	switch withCode {
	case 500:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "internal server error",
				"message": "error retrieving secret",
			},
		})

		return

	case 501:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("<html><body>This is some HTML error that can happen</body></html>"))

		return

	case 502:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"fault": map[string]string{
				"msg": "good json syntax but badly formatted error message",
			},
		})

		return

	case 401:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(401)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "unauthorized",
				"message": "invalid authentication credentials when retrieving certificate",
			},
		})

		return

	case 404:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(404)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "not_found",
				"message": fmt.Sprintf("certificate %s not found in this keyvault", certificateName),
			},
		})

		return

	case 403:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(403)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "forbidden",
				"message": "not allowed on this specific tenant perhaps when retrieving secret",
			},
		})

		return

	default:
		if withCode == 0 || withCode == 200 {
			authHeader := r.Header.Get("Authorization")

			//if contains(Tokens, authHeader) {
			if expiresAt, ok := Tokens[authHeader]; ok {
				if time.Now().Unix() > expiresAt {
					// Unauthorized
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusUnauthorized)
					json.NewEncoder(w).Encode(AzureError{
						&AzureErrorDetail{
							Code:    "Unauthorized",
							Message: "[TokenExpired] Error validating token: 'S2S12086'.",
						},
					})
				} else {
					// Good
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusOK)

					certObject := &AzureCertificate{}
					json.Unmarshal([]byte(`{    "attributes": {        "created": 1673029993,        "enabled": true,        "exp": 1704565993,        "nbf": 1673029393,        "recoverableDays": 7,        "recoveryLevel": "CustomizedRecoverable+Purgeable",        "updated": 1673029993    },    "cer": "MIIDPDCC...==",    "id": "https://localhost",    "kid": "https://localhost",    "pending": {        "id": "https://localhost"    },    "policy": {        "attributes": {            "created": 1673029989,            "enabled": true,            "updated": 1673029989        },        "id": "https://localhost",        "issuer": {            "name": "Self"        },        "key_props": {            "exportable": true,            "key_size": 2048,            "kty": "RSA",            "reuse_key": false        },        "lifetime_actions": [            {                "action": {                    "action_type": "AutoRenew"                },                "trigger": {                    "lifetime_percentage": 80                }            }        ],        "secret_props": {            "contentType": "application/x-pem-file"        },        "x509_props": {            "basic_constraints": {                "ca": false            },            "ekus": [                "1.3.6.1.5.5.7.3.1",                "1.3.6.1.5.5.7.3.2"            ],            "key_usage": [                "digitalSignature",                "keyEncipherment"            ],            "sans": {                "dns_names": []            },            "subject": "CN=test-certificate",            "validity_months": 12        }    },    "sid": "https://localhost",    "tags": {},    "x5t": "wOSk8759bvVk2tJc32vnVASBRLk"}`), certObject)

					certObject.ID = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/certificates/%s/%s", vaultName, certificateName, certificateVersion)
					certObject.Kid = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/keys/%s/%s", vaultName, certificateName, certificateVersion)
					certObject.Sid = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/certificates/%s/%s", vaultName, certificateName, certificateVersion)
					certObject.Policy.ID = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/certificates/%s/policy", vaultName, certificateName)
					certObject.Pending.ID = fmt.Sprintf("http://fakeazure:8081/keyvault/%s/certificates/%s/pending", vaultName, certificateName)

					json.NewEncoder(w).Encode(certObject)
				}
			} else {
				// Unauthorized
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				json.NewEncoder(w).Encode(AzureError{
					&AzureErrorDetail{
						Code:    "Unauthorized",
						Message: "[BearerReadAccessTokenFailed] Error validating token: 'S2S12005'.",
					},
				})
			}

		} else {
			// Nonspecific fake error code
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(withCode)
			json.NewEncoder(w).Encode(map[string]string{
				"nonspecific error": "error retrieving secret",
			})

		}
	}
}

func KeyVaultGetSecretVersion(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	secretVersion := vars["secretVersion"]

	KeyVaultGetSecret(w, r, secretVersion)
}

func KeyVaultGetSecretDefault(w http.ResponseWriter, r *http.Request) {
	KeyVaultGetSecret(w, r, "9bdcdbefc49446dd9a28e04f55e10340")
}

func KeyVaultGetSecret(w http.ResponseWriter, r *http.Request, secretVersion string) {
	vars := mux.Vars(r)
	secretName, ok := vars["secretName"]
	if !ok {
		log.Println("Not secretName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}
	vaultName, ok := vars["vaultName"]
	if !ok {
		log.Println("Not vaultName specified")
		// do an error
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"generic error": "error",
		})
	}

	// Check if we want a fake error
	var withCode int = 0
	var err error

	withCodeRaw := r.URL.Query().Get("withcode")
	if withCodeRaw != "" {
		withCode, err = strconv.Atoi(withCodeRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error": map[string]string{
					"code":    "internal server error",
					"message": "could not parse 'withcode' as an integer when retrieving secret",
				},
			})

			return
		}
	}

	switch withCode {
	case 500:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "internal server error",
				"message": "error retrieving secret",
			},
		})

		return

	case 501:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("<html><body>This is some HTML error that can happen</body></html>"))

		return

	case 502:
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"fault": map[string]string{
				"msg": "good json syntax but badly formatted error message",
			},
		})

		return

	case 401:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(401)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "unauthorized",
				"message": "invalid authentication credentials when retrieving secret",
			},
		})

		return

	case 403:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(403)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "forbidden",
				"message": "not allowed on this specific tenant perhaps when retrieving secret",
			},
		})

		return

	case 404:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(404)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]string{
				"code":    "not_found",
				"message": fmt.Sprintf("secret %s version %s not found in this keyvault", secretName, secretVersion),
			},
		})

		return

	default:
		if withCode == 0 || withCode == 200 {
			authHeader := r.Header.Get("Authorization")

			//if contains(Tokens, authHeader) {
			if expiresAt, ok := Tokens[authHeader]; ok {
				if time.Now().Unix() > expiresAt {
					// Unauthorized
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusUnauthorized)
					json.NewEncoder(w).Encode(AzureError{
						&AzureErrorDetail{
							Code:    "Unauthorized",
							Message: "[BearerReadAccessTokenFailed] Token expired: 'S2S120010'.",
						},
					})
				} else {
					// Good
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusOK)
					json.NewEncoder(w).Encode(KeyVaultGetSecretResponse{
						Attributes: &KeyVaultAttributes{
							Created:         1660313443,
							Enabled:         true,
							Expiry:          1723385117,
							RecoverableDays: 7,
							RecoveryLevel:   "CustomizedRecoverable+Purgeable",
							Updated:         1660313868,
						},
						ID:    fmt.Sprintf("http://fakeazure:8081/keyvault/%s/secrets/%s/%s", vaultName, secretName, secretVersion),
						Tags:  map[string]string{},
						Value: "This is the fake secret value",
					})
				}
			} else {
				// Unauthorized
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				json.NewEncoder(w).Encode(AzureError{
					&AzureErrorDetail{
						Code:    "Unauthorized",
						Message: "[BearerReadAccessTokenFailed] Error validating token: 'S2S12005'.",
					},
				})
			}

		} else {
			// Nonspecific fake error code
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(withCode)
			json.NewEncoder(w).Encode(map[string]string{
				"nonspecific error": "error retrieving secret",
			})

		}
	}
}
