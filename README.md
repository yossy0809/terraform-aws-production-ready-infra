# AWS 3層Webインフラ構成 ポートフォリオ

## 概要

オンプレミス環境を想定した3層Webシステムを、TerraformでAWS上に構築したポートフォリオです。  
可用性・セキュリティ・運用性を意識したインフラ設計を実装しています。

---

## 構成図

![構成図](./diagram.png)

---

## 使用技術

| カテゴリ | 技術・サービス |
|---|---|
| IaC | Terraform |
| ネットワーク | AWS VPC / Subnet / Route Table / Internet Gateway / NAT Gateway |
| 配信・負荷分散 | Amazon CloudFront / ALB (Multi-AZ) |
| コンピューティング | Amazon EC2 / Auto Scaling Group |
| データベース | Amazon RDS MySQL (Multi-AZ) |
| セキュリティ | AWS IAM / Security Group / AWS SSM Parameter Store |
| 運用 | AWS Systems Manager Session Manager |

---

## インフラ構成の詳細

### ネットワーク設計

VPCを3層のサブネットに分割し、各層の役割を明確に分離しています。

| サブネット | CIDR | 配置リソース |
|---|---|---|
| Public Subnet | 10.0.1.0/24 (1a) / 10.0.2.0/24 (1c) | ALB / NAT Gateway |
| Private Subnet | 10.0.11.0/24 (1a) / 10.0.12.0/24 (1c) | EC2 |
| DB Subnet | 10.0.21.0/24 (1a) / 10.0.22.0/24 (1c) | RDS |

DBサブネットには専用のルートテーブルを割り当て、インターネットへの経路を持たない設計にしています。

### セキュリティ設計

セキュリティグループで、必要な通信のみを許可しています。

```
Internet
  ↓ HTTPS（443）
CloudFront
  ↓ HTTP（80） — CloudFront エッジノードIPのみ許可
ALB Security Group
  ↓ ALB SGからの通信のみ許可
EC2 Security Group
  ↓ EC2 SGからの通信のみ許可
RDS Security Group
```

ALBのセキュリティグループは、AWSマネージドプレフィックスリスト（`com.amazonaws.global.cloudfront.origin-facing`）を使用して、CloudFrontエッジノードのIPからのみHTTPを許可しています。これにより、ALBへの直接アクセスをブロックし、必ずCloudFront経由でのみ公開される設計にしています。

EC2へのログインはSSH（キーペア）を使用せず、**SSM Session Manager**を採用しています。  
これによりポート22を完全にクローズし、よりセキュアな運用を実現しています。

### 可用性設計

| リソース | 設計 | 目的 |
|---|---|---|
| CloudFront | グローバルエッジロケーション | 静的コンテンツのキャッシュ・レイテンシ低減 |
| ALB | Multi-AZ | 単一AZ障害時の継続稼働 |
| EC2 | Auto Scaling Group (Private Subnet 1a / 1c、min:1 / max:2 / desired:1) | インターネットから直接到達不可・単一AZ障害時の継続稼働 |
| RDS | Multi-AZ (1a Primary / 1c Standby) | 障害時の自動フェイルオーバー |
| NAT Gateway | Public Subnetに配置 | Privateサブネットからの安全なアウトバウンド通信 |

### DBパスワード管理

RDSのマスターパスワードはコードにベタ書きせず、**AWS Systems Manager Parameter Store（SecureString）** で管理しています。  
TerraformのSensitive変数と組み合わせることで、`terraform plan`の出力にもパスワードが表示されない設計にしています。

---

## 設計方針

### 可用性

単一障害点（SPOF）を排除するため、ALB・RDS・EC2（Auto Scaling Group）をMulti-AZ構成にしています。  
RDSはMulti-AZによる自動フェイルオーバーに対応しており、プライマリ障害時も短時間でスタンバイに切り替わります。  
CloudFrontのエッジロケーションを利用することで、静的コンテンツのキャッシュによるレスポンス向上と、オリジンサーバーへの負荷軽減を実現しています。

### セキュリティ

- EC2・RDSはPrivate/DBサブネットに配置し、インターネットから直接到達できない構成
- DBサブネットは専用ルートテーブルを使用し、インターネットへの経路を持たない
- ALBはAWSマネージドプレフィックスリストでCloudFrontエッジノードIPのみ許可し、直接アクセスをブロック
- セキュリティグループの連鎖参照により、各層間の通信を最小権限で制御
- SSM Session Managerによりポート22（SSH）を完全クローズ
- DBパスワードをParameter Store（SecureString）で暗号化管理
- RDSストレージを暗号化（`storage_encrypted = true`）

### IaC（Infrastructure as Code）

全構成をTerraformでコード化しています。  
手作業によるミスを排除し、環境の再現性と変更管理を担保しています。

---

## 改善余地（本番環境を想定した場合）

現在のポートフォリオ構成から、本番導入時に追加すべき要素を整理しています。

| 項目 | 内容 |
|---|---|
| Auto Scaling のメトリクス連動 | 現状は希望台数固定（desired:1）。本番ではCPU使用率等のメトリクスに応じたスケーリングポリシーを追加 |
| HTTPS化 | ACM（AWS Certificate Manager）で証明書を取得し、CloudFrontおよびALBに適用 |
| WAF導入 | AWS WAFをCloudFrontに適用し、SQLインジェクション・XSS等を防御 |
| NAT Gateway冗長化 | 現状は1AZのみ。本番では各AZにNAT Gatewayを配置してAZ障害に対応 |
| CloudTrail | API操作ログを取得し、セキュリティインシデント時の証跡を確保 |
| AWS Config | リソース設定変更の記録・コンプライアンスチェックを自動化 |

---

- **インフラ経験**：5年（Linux / ネットワーク設計構築 / Windows Server / 仮想化 / 監視・障害対応）
- **AWS資格**：AWS SAA / AWS SAP 取得済
