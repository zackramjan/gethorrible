FROM perl:latest
RUN cd /root && \
	git clone https://github.com/zackramjan/getnyaa.git && \
	apt-get update &&  \
	apt install -y libxml-simple-perl 
