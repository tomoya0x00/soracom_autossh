# soracom_autossh

SORACOM Airでインターネットに接続したLinuxデバイスに対し、リモートからSSHを可能にするスクリプトです。  
クラスメソッド様の[Soracom Airで繋がったデバイスにリモートからSSHする](http://dev.classmethod.jp/etc/remote-port-forward-with-soracom-and-autossh/)を参考に、SORACOM Airのユーザーデータをパースしてautosshを起動します。  
cronなどでの定期実行を想定しています。

## require

* ssh
* autossh
* jq
* curl

## 事前準備

* SSHでログイン可能なグローバルIPが割り振られたリモートサーバを用意
  * AWS EC2など
  * SSHは公開鍵方式でログインできるようにしておく
* SORACOM Airでインターネットに接続するLinuxデバイスを用意
  * RaspberryPiやOpenBlocksIoTなど
  
## 使用方法

1.リモートサーバとLinuxデバイスを起動  
2.[SORACOM Air メタデータサービスのご紹介](https://blog.soracom.jp/blog/2015/11/27/air-metadata/)を参考に、メタデータサービスを有効化  
3.メタデータサービスのユーザーデータに下記を入力して保存
``` json
{
  "ssh":{
    "imsis":{
      "{SSHでログインしたいLinuxデバイスのSORACOM Air IMSI}":{
        "portForwardParam":"{任意のポート番号}:localhost:22 {リモートサーバのユーザー名}@{リモートサーバのグローバルIPアドレス}",
        "privateKey":"{リモートサーバのSSH秘密鍵}"
      }
    }
  }
}
```
4.Linuxデバイスでsoracom_autossh.shを実行  started autosshと表示されればOK  
5.リモートサーバで"$ ssh localhost -p {ユーザーデータに指定した任意のポート番号}"を実行すれば、ログイン可能

## 補足

* cronなどでの定期実行を想定しており、autossh起動後にユーザーデータから自分のIMSIが消えた場合はautosshを終了します
* ユーザーデータのimsisには複数のIMSIを指定可能です。
