ARG UBUNTU_VERSION
ARG CUDA_VERSION

# ========= 构建阶段：安装 pyenv 和 Python =========
FROM ubuntu:${UBUNTU_VERSION} AS builder

ARG PYTHON_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV PYENV_ROOT=/opt/pyenv
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH

# 安装 pyenv 依赖及 Python 构建依赖

RUN apt-get update && apt-get install -y --no-install-recommends build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev \
    liblzma-dev ca-certificates

# 安装 pyenv 并构建 Python
RUN git clone --branch v2.6.6 https://github.com/pyenv/pyenv.git $PYENV_ROOT && \
    pyenv install $PYTHON_VERSION && pyenv global $PYTHON_VERSION && python -m pip install --upgrade pip

COPY entrypoint.sh /entrypoint.sh
COPY 99-system-info /99-system-info

RUN chmod +x /entrypoint.sh && chmod +x /99-system-info && sed -i 's/\r$//' /entrypoint.sh && sed -i 's/\r$//' /99-system-info

# ======= 生产阶段 ==========
FROM nvidia/cuda:${CUDA_VERSION}-cudnn-runtime-ubuntu${UBUNTU_VERSION}

ARG PYTHON_VERSION
ARG TORCH_VERSION

ENV PYENV_ROOT=/opt/pyenv
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH

# 拷贝 pyenv 和 Python 安装结果
COPY --from=builder /opt/pyenv /opt/pyenv
COPY --from=builder /entrypoint.sh /entrypoint.sh
COPY --from=builder /99-system-info /etc/update-motd.d/99-system-info

# 设置默认 Python 版本为 pyenv 的版本
RUN pyenv global ${PYTHON_VERSION}

# 安装运行时依赖
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "export PYENV_ROOT=\"$PYENV_ROOT\"" >> ~/.bashrc && \
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc

# 安装 PyTorch
RUN pip install torch==${TORCH_VERSION}+cu126 tensorboard \
    --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cu126 \
    --extra-index-url https://pypi.org/simple

# 验证
# RUN python -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())"

# 暴露端口
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
