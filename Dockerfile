FROM ubuntu:22.04

RUN apt update && apt install -y \
	build-essential \
    wget \
    cmake \
    pkg-config \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libncurses-dev\
    python3 \
    python3-pip \
    python3-venv && \
    rm -rf /var/lib/apt/lists/*

ENV SOFT=/soft
ENV LIBDEFLATE_VERSION=1.25

#ENV HTSLIB_VERSION=1.24
#ENV BCFTOOLS_VER=1.24 
ENV SAMTOOLS_VERSION=1.24  
# Поскольку выпускаются параллельно и связанно, то версия у них одна

ENV VCFTOOLS_VERSION=0.1.17

#переменные окружения

ENV SAMTOOLS="${SOFT}/samtools-${SAMTOOLS_VERSION}/bin/samtools" 
ENV BCFTOOLS="${SOFT}/bcftools-${SAMTOOLS_VERSION}/bin/bcftools" 
ENV VCFTOOLS="${SOFT}/vcftools-${SAMTOOLS_VERSION}/bin/vcftools"

ENV PATH="${SOFT}/samtools-${SAMTOOLS_VERSION}/bin:${SOFT}/bcftools-${SAMTOOLS_VERSION}/bin:${SOFT}/vcftools-${VCFTOOLS_VERSION}/bin:${SOFT}/htslib-${SAMTOOLS_VERSION}/bin:$PATH"

ENV PKG_CONFIG_PATH="${SOFT}/libdeflate-${LIBDEFLATE_VERSION}/lib/pkgconfig:${SOFT}/htslib-${SAMTOOLS_VERSION}/lib/pkgconfig:${PKG_CONFIG_PATH}"
ENV LD_LIBRARY_PATH="${SOFT}/libdeflate-${LIBDEFLATE_VERSION}/lib:${SOFT}/htslib-${SAMTOOLS_VERSION}/lib:${LD_LIBRARY_PATH}"
ENV C_INCLUDE_PATH="${SOFT}/libdeflate-${LIBDEFLATE_VERSION}/include:${SOFT}/htslib-${SAMTOOLS_VERSION}/include:${C_INCLUDE_PATH}"

WORKDIR /tmp/build

#слои - для каждой библиотеки свой

RUN wget https://github.com/ebiggers/libdeflate/releases/download/v${LIBDEFLATE_VERSION}/libdeflate-${LIBDEFLATE_VERSION}.tar.gz && \
	tar -xzf libdeflate-${LIBDEFLATE_VERSION}.tar.gz && \
	cd libdeflate-${LIBDEFLATE_VERSION} && \
	cmake -B build --install-prefix $SOFT/libdeflate-${LIBDEFLATE_VERSION} && \
	cmake --build build -j$(($(nproc)-1)) && \
	cmake --install build && \
	cd .. && \
	rm -rf libdeflate-${LIBDEFLATE_VERSION}.tar.gz libdeflate-${LIBDEFLATE_VERSION}

RUN wget https://github.com/samtools/htslib/releases/download/${SAMTOOLS_VERSION}/htslib-${SAMTOOLS_VERSION}.tar.bz2  && \
	tar -xjf htslib-${SAMTOOLS_VERSION}.tar.bz2 && \
	cd htslib-${SAMTOOLS_VERSION} && \
	./configure --prefix=${SOFT}/htslib-${SAMTOOLS_VERSION} && \
	make -j$(($(nproc)-1)) && \
	make install && \
	cd .. && \
	rm -rf htslib-${SAMTOOLS_VERSION}.tar.bz2 htslib-${SAMTOOLS_VERSION} 
	
RUN wget https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2  && \
	tar -xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 && \
	cd samtools-${SAMTOOLS_VERSION} && \
	./configure --prefix=${SOFT}/samtools-${SAMTOOLS_VERSION} --with-htslib=${SOFT}/htslib-${SAMTOOLS_VERSION} && \
	make -j$(($(nproc)-1)) && \
	make install && \
	cd .. && \
	rm -rf samtools-${SAMTOOLS_VERSION}.tar.bz2 samtools-${SAMTOOLS_VERSION}

RUN wget https://github.com/samtools/bcftools/releases/download/${SAMTOOLS_VERSION}/bcftools-${SAMTOOLS_VERSION}.tar.bz2  && \
	tar -xjf bcftools-${SAMTOOLS_VERSION}.tar.bz2 && \
	cd bcftools-${SAMTOOLS_VERSION} && \
	./configure --prefix=${SOFT}/bcftools-${SAMTOOLS_VERSION} --with-htslib=${SOFT}/htslib-${SAMTOOLS_VERSION} && \
	make -j$(($(nproc)-1)) && \
	make install && \
	cd .. && \
	rm -rf bcftools-${SAMTOOLS_VERSION}.tar.bz2 bcftools-${SAMTOOLS_VERSION}

RUN wget https://github.com/vcftools/vcftools/releases/download/v${VCFTOOLS_VERSION}/vcftools-${VCFTOOLS_VERSION}.tar.gz  && \
	tar -xzf vcftools-${VCFTOOLS_VERSION}.tar.gz  && \
	cd vcftools-${VCFTOOLS_VERSION} && \
	./configure --prefix=${SOFT}/vcftools-${VCFTOOLS_VERSION} && \
	make -j$(($(nproc)-1)) && \
	make install && \
	cd .. && \
	rm -rf vcftools-${VCFTOOLS_VERSION}.tar.gz vcftools-${VCFTOOLS_VERSION}


WORKDIR /
RUN rm -rf /tmp/build && ldconfig

CMD ["/bin/bash"]
