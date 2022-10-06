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

func InstanceMetadataTokenGet(w http.ResponseWriter, r *http.Request) {
	// Check if we want a fake error
	var withCode int = 0
	var err error

	withCodeRaw := r.URL.Query().Get("withcodemanagedidentity")
	if withCodeRaw != "" {
		withCode, err = strconv.Atoi(withCodeRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"internal server error": "could not parse 'withcode' as an integer",
			})

			return
		}
	}

	var withExpiry int = 30
	withExpiryRaw := r.URL.Query().Get("withexpiry")
	if withExpiryRaw != "" {
		withExpiry, err = strconv.Atoi(withExpiryRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"internal server error": "could not parse 'withexpiry' as an integer",
			})

			return
		}
	}

	switch withCode {
	case 500:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"internal server error on managed identiy endpoint": "error",
		})

		return

	case 401:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(401)
		json.NewEncoder(w).Encode(map[string]string{
			"unauthorized": "wrong client id or something on managed identiy endpoint",
		})

		return

	case 403:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(403)
		json.NewEncoder(w).Encode(map[string]string{
			"forbidden": "not allowed on this specific tenant perhaps on managed identiy endpoint",
		})

		return

	default:
		if withCode == 0 || withCode == 200 {
			// Good, generate a fake Bearer and cache it as authorised
			randToken := RandStringRunes(50)
			expiresAt := time.Now().Unix() + int64(withExpiry)
			Tokens[fmt.Sprintf("Bearer %s", randToken)] = expiresAt

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(OAuthResponse{
				AccessToken:  randToken,
				ExpiresIn:    int32(withExpiry),
				ExtExpiresIn: int32(withExpiry),
				TokenType:    "Bearer",
			})
		} else {
			// Nonspecific fake error code
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(withCode)
			json.NewEncoder(w).Encode(map[string]string{
				"nonspecific error on managed identiy endpoint": "error",
			})
		}
	}
}

func OAuthTokenPost(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	_, ok := vars["tenantId"]
	if !ok {
		log.Println("tenantId is required in URL ('/{tenantId}/oauth2/v2.0/token')")
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
			json.NewEncoder(w).Encode(map[string]string{
				"internal server error": "could not parse 'withcode' as an integer",
			})

			return
		}
	}

	var withExpiry int = 30
	withExpiryRaw := r.URL.Query().Get("withexpiry")
	if withExpiryRaw != "" {
		withExpiry, err = strconv.Atoi(withExpiryRaw)

		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"internal server error": "could not parse 'withexpiry' as an integer",
			})

			return
		}
	}

	switch withCode {
	case 500:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"internal server error": "error",
		})

		return

	case 401:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(401)
		json.NewEncoder(w).Encode(map[string]string{
			"unauthorized": "wrong client id or something",
		})

		return

	case 403:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(403)
		json.NewEncoder(w).Encode(map[string]string{
			"forbidden": "not allowed on this specific tenant perhaps",
		})

		return

	default:
		if withCode == 0 || withCode == 200 {
			// Good, generate a fake Bearer and cache it as authorised
			randToken := RandStringRunes(50)
			expiresAt := time.Now().Unix() + int64(withExpiry)
			Tokens[fmt.Sprintf("Bearer %s", randToken)] = expiresAt

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(OAuthResponse{
				AccessToken:  randToken,
				ExpiresIn:    int32(withExpiry),
				ExtExpiresIn: int32(withExpiry),
				TokenType:    "Bearer",
			})
		} else {
			// Nonspecific fake error code
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(withCode)
			json.NewEncoder(w).Encode(map[string]string{
				"nonspecific error": "error",
			})
		}
	}
}
