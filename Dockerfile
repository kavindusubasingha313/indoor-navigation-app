FROM node:22-bookworm-slim AS node
FROM python:3.12-slim-bookworm

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY requirements.txt /tmp/dependencies/runtime.txt
COPY ci/requirements.txt /tmp/dependencies/constraints.txt
RUN python -m pip install --no-cache-dir \
    -c /tmp/dependencies/constraints.txt -r /tmp/dependencies/runtime.txt

COPY . /app
RUN jac install --dev && jac build main.jac \
    && groupadd --gid 10001 navijac \
    && useradd --uid 10001 --gid navijac --create-home navijac \
    && mkdir -p /app/.jac/data \
    && chown -R navijac:navijac /app

USER navijac
EXPOSE 8000
VOLUME ["/app/.jac/data"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:'+os.environ.get('PORT','8000')+'/openapi.json',timeout=3)"
CMD ["python", "deploy/start.py"]
