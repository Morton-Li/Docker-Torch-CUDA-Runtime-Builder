# Docker Torch CUDA Runtime Builder

本项目用于构建一套自定义 Docker 镜像，解决默认运行时环境版本过低，以及多环境手动搭建配置繁琐的问题。本项目同时支持在多个云 GPU 平台上快速部署推理与训练环境。

---

## 🚀 快速开始 | How to Use

### ✅ 直接使用（推荐）

1. 访问 [Docker Hub 页面](https://hub.docker.com/r/mortonli/torch-cuda-runtime) ，并选择所需的镜像标签  
    例如：`torch2.7.0-cu12.6.3-cudnn9.5.1-ubuntu24.04`
2. 配置环境变量 `ROOT_PASSWORD` 或 `ROOT_AUTHORIZED_KEY`：
   - `ROOT_PASSWORD`：容器启动时自动配置的 root 密码
   - `ROOT_AUTHORIZED_KEY`：容器启动时自动配置的 SSH 公钥
3. 启动容器并运行你的 PyTorch 推理或训练任务。
   
### 🧩 自定义构建

1. Fork 本项目；
2. 配置 GitHub Actions Secrets：
   - `DOCKER_USERNAME`：你的 Docker Hub 用户名
   - `DOCKER_ACCESS_TOKEN`：对应账户的访问令牌
3. 根据需要修改 Dockerfile 或构建配置；
4. 提交至 `main` 分支，GitHub Actions 将自动触发构建并推送镜像至 Docker Hub。

---

## 📁 项目结构说明

```
.
├── Dockerfile              # 构建镜像的主文件
├── Dockerfile_torch-only   # 仅安装 PyTorch 的 Dockerfile
├── entrypoint.sh           # 容器启动时执行的脚本
├── 99-system-info          # MOTD
├── README.md               # 项目说明文件
└── .github/workflows/
    └── auto-build.yml      # GitHub Actions 自动构建配置文件
```

---

## 🤝 鸣谢 Acknowledgements

- [GitHub Actions](https://github.com/features/actions)
- [Docker](https://www.docker.com/)
- [PyTorch](https://github.com/pytorch/pytorch)
- [Nvidia](https://www.nvidia.com/)
