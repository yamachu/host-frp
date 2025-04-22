ローカルで https で動作してるアプリケーションに対して proxy 出来ないか調べてた残骸

client側のconfig
```
serverAddr = "ここにNLBのやつ"
serverPort = 7000

auth.method = "token"
auth.token = "ここにToken"

[[proxies]]
name = "test-http"
type = "http"
customDomains = ["NLBのやつ"]

[proxies.plugin]
type = "http2https"
localAddr = "向けたいlocalのアプリケーションURL"
hostHeaderRewrite = "向けたいlocalのアプリケーションURL"

[[proxies]]
name = "test-https"
type = "https"
customDomains = ["NLBのやつ"]

[proxies.plugin]
type = "https2https"
localAddr = "向けたいlocalのアプリケーションURL"
hostHeaderRewrite = "向けたいlocalのアプリケーションURL"
```

8080だと行けるけど…
frpcの方をSSL終端にして、https2httpsで自己署名証明書をこの設定に突っ込むのがいいのかなとなったが試してない
