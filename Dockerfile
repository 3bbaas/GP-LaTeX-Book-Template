FROM texlive/texlive:TL2024-historic

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pygments make && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash builder

WORKDIR /book

USER builder

CMD ["make", "build"]
