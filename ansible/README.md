# Ansible

`infra01`と`game01`の共通設定を再現するためのAnsible定義。

## 管理対象

- QEMU Guest Agent
- SSH公開鍵認証、root SSH・パスワード認証の無効化
- UFW（管理PCからのSSHだけを許可）
- Docker Engine / Docker Compose plugin

ゲームサーバーのCompose定義、ゲームワールド、外部公開、バックアップは管理対象外とする。

## 実行ホスト

管理PCのWSLなど、SSH秘密鍵を安全に利用できるLinux環境で実行する。`infra01`をAnsible実行ホストにせず、管理用SSH秘密鍵をVMへ配置しない。

## 初期設定

```bash
cd ansible
cp -R inventories/example inventories/local
# inventories/local/hosts.yml と group_vars/all.yml のプレースホルダーを実環境値へ置換
export ANSIBLE_ROLES_PATH="$PWD/roles"
ansible-playbook -i inventories/local/hosts.yml playbooks/common.yml --syntax-check
ansible-playbook -i inventories/local/hosts.yml playbooks/common.yml --check
ansible-playbook -i inventories/local/hosts.yml playbooks/common.yml
```

WSLからWindowsドライブ上のリポジトリを実行する場合、Ansibleは安全上の理由で`ansible.cfg`を自動読込しない。上記の`ANSIBLE_ROLES_PATH`指定を必ず付ける。

`inventories/local/`はGit管理しない。初回の静的IP設定は既存手順で行い、Ansibleは疎通確立後の共通設定を担当する。
