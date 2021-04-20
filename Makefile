# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ysoroko <ysoroko@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2021/04/20 11:52:55 by ysoroko           #+#    #+#              #
#    Updated: 2021/04/20 12:28:59 by ysoroko          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# build: Build our container:
# "-t" allows to specify the name of the created container
# "." tells where to look for Dockerfile
build:
	docker build -t ft_server .


# run: Run our container:
# "-it" Allows to enter the containers terminal ("-i" = in a "pretty" format)
# "-rm" Removes the container when we exit from it
# "-p" Links the ports between the container and our computer. 
# The container has no access to outside world, we need to connect its ports
# to the same ports of our computer to use our computer's connection
run:
	docker run -it --rm -p 80:80 -p 443:443 ft_server


# kill: will stop all of our running containers immediately
# We can alse use "stop" command instead of "kill", but it will wait
# for 10s before stopping the containers which is a bit long
kill:
	-docker kill `docker ps -qa`


# iclean: Removes all the images
# "-q" option is used to provide each image's unique ID
# If there are no images calling this Makefile rule will give an error
iclean: kill
	-docker rmi `docker images -q`


# cclean: Removes all the containers
# "-q" option is used to provide each container's unique ID
# If there are no containers, calling this Makefile rule will give an error
cclean: kill
	-docker rm `docker ps -qa`


# prune: Cleans up temporary files and other leftovers in memory
prune:
	docker system prune
