#!/usr/bin/env bash
set -euo pipefail

install_dir=/opt/bin
mkdir -p "${install_dir}" /var/log/digdag

export PATH="${install_dir}:${PATH}"
# GEM_HOME/GEM_PATH は embulk が自動で ~/.embulk 配下を作るので設定不要

###############################################################################
# Digdag 0.10.4
###############################################################################
curl -fsSL -o "${install_dir}/digdag"  \
  https://dl.digdag.io/digdag-0.10.4
chmod +x "${install_dir}/digdag"

###############################################################################
# Embulk 0.9.24  (GitHub Releases)
###############################################################################
EMBULK_VER=0.9.24
curl -fsSL -o "${install_dir}/embulk" \
  "https://github.com/embulk/embulk/releases/download/v${EMBULK_VER}/embulk-${EMBULK_VER}.jar"
chmod +x "${install_dir}/embulk"

###############################################################################
# Spark 3.3.4  +  PySpark 3.3.4   ★★★ ここを書き換え ★★★
###############################################################################
SPARK_VER=3.3.4          # ← 3 系にアップ
HADOOP_VER=3              # Hadoop-3.3 ビルド
curl -fsSL -o /tmp/spark.tgz \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}.tgz"
tar -C /opt -xzf /tmp/spark.tgz
mv "/opt/spark-${SPARK_VER}-bin-hadoop${HADOOP_VER}" /opt/spark
rm /tmp/spark.tgz

# Python へのリンク（無ければ）
command -v python >/dev/null 2>&1 || ln -s /usr/bin/python3 /usr/bin/python

# Spark 環境変数
export SPARK_HOME=/opt/spark
export PATH="${install_dir}:${PATH}:${SPARK_HOME}/bin"

# PySpark を Spark とそろえたバージョンでインストール
pip3 --version >/dev/null 2>&1 || (apt-get update && apt-get install -y python3-pip)
pip3 install --no-cache-dir pyspark==${SPARK_VER}

###############################################################################
# Embulk plugins
###############################################################################
# jruby-openssl だけバージョン固定
embulk gem install jruby-openssl:0.9.21

# そのほかは最新版で OK
embulk gem install embulk-input-postgresql \
                   embulk-output-postgresql \
                   embulk-output-parquet

###############################################################################
# Digdag server
###############################################################################
exec digdag server \
  --config /root/etc/digdag.properties \
  --bind 0.0.0.0 --port 65432 \
  --task-log /var/log/digdag --access-log /var/log/digdag


