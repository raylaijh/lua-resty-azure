package main

type OAuthRequest struct {
	ClientID     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	GrantType    string `json:"grant_type"`
	Scope        string `json:"scope"`
}

type OAuthResponse struct {
	AccessToken  string `json:"access_token"`
	ExpiresIn    int32  `json:"expires_in"`
	ExtExpiresIn int32  `json:"ext_expires_in"`
	TokenType    string `json:"token_type"`
}

type AzureCertificate struct {
	Attributes struct {
		Created         int    `json:"created"`
		Enabled         bool   `json:"enabled"`
		Exp             int    `json:"exp"`
		Nbf             int    `json:"nbf"`
		RecoverableDays int    `json:"recoverableDays"`
		RecoveryLevel   string `json:"recoveryLevel"`
		Updated         int    `json:"updated"`
	} `json:"attributes"`
	Cer     string `json:"cer"`
	ID      string `json:"id"`
	Kid     string `json:"kid"`
	Pending struct {
		ID string `json:"id"`
	} `json:"pending"`
	Policy struct {
		Attributes struct {
			Created int  `json:"created"`
			Enabled bool `json:"enabled"`
			Updated int  `json:"updated"`
		} `json:"attributes"`
		ID     string `json:"id"`
		Issuer struct {
			Name string `json:"name"`
		} `json:"issuer"`
		KeyProps struct {
			Exportable bool   `json:"exportable"`
			KeySize    int    `json:"key_size"`
			Kty        string `json:"kty"`
			ReuseKey   bool   `json:"reuse_key"`
		} `json:"key_props"`
		LifetimeActions []struct {
			Action struct {
				ActionType string `json:"action_type"`
			} `json:"action"`
			Trigger struct {
				LifetimePercentage int `json:"lifetime_percentage"`
			} `json:"trigger"`
		} `json:"lifetime_actions"`
		SecretProps struct {
			ContentType string `json:"contentType"`
		} `json:"secret_props"`
		X509Props struct {
			BasicConstraints struct {
				Ca bool `json:"ca"`
			} `json:"basic_constraints"`
			Ekus     []string `json:"ekus"`
			KeyUsage []string `json:"key_usage"`
			Sans     struct {
				DNSNames []interface{} `json:"dns_names"`
			} `json:"sans"`
			Subject        string `json:"subject"`
			ValidityMonths int    `json:"validity_months"`
		} `json:"x509_props"`
	} `json:"policy"`
	Sid  string `json:"sid"`
	Tags struct {
	} `json:"tags"`
	X5T string `json:"x5t"`
}

type AzureKey struct {
	Attributes struct {
		Created         int    `json:"created"`
		Enabled         bool   `json:"enabled"`
		RecoverableDays int    `json:"recoverableDays"`
		RecoveryLevel   string `json:"recoveryLevel"`
		Updated         int    `json:"updated"`
	} `json:"attributes"`
	Key struct {
		E      string   `json:"e"`
		KeyOps []string `json:"key_ops"`
		Kid    string   `json:"kid"`
		Kty    string   `json:"kty"`
		N      string   `json:"n"`
	} `json:"key"`
	Tags struct {
	} `json:"tags"`
}
