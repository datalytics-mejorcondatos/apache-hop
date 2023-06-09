## Ejecución con Docker en AWS

Para ejecutar un proceso desde un contenedor de Docker, podemos seguir los siguientes pasos:

1. Instanciamos un entorno de AWS Cloud9, allí tendremos una interfaz visual de desarrollo desde donde podremos conectarnos a los servicios de AWS que necesitemos, de esta manera evitamos tener que configurar nuestra PC para conectarnos a AWS.
2. Una vez listo el entorno, utilizamos la interfaz de git para clonar este repositrio.
3. Luego, actualizamos el cliente de línea de comandos de AWS siguiendo [estas](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instrucciones.
4. Generamos la imagen de docker con el Dockerfile ubicado en automatizacion/docker, esto ejecutando el siguiente comando desde una terminal: ```docker build -t hop:2.3 -f Dockerfile .```
5. Una vez que tenemos la imagen en el entorno, la subimos al servicio de registro de contenedores AWS ECR, para ello tenemos que ejecutar los siguientes comandos, reemplazando *region_a_utilizar* y *numero_de_cuenta* según corresponda. Antes de ejecutar los comandos debemos crear el repositorio *hop* en la consola de ECR:

```
aws ecr get-login-password --region *region_a_utilizar* | docker login --username AWS --password-stdin *numero_de_cuenta*.dkr.ecr.*region_a_utilizar*.amazonaws.com
docker tag hop:2.3 *numero_de_cuenta*.dkr.ecr.*region_a_utilizar*.amazonaws.com/hop:2.3
docker push *numero_de_cuenta*.dkr.ecr.*region_a_utilizar*.amazonaws.com/hop:2.3
```

Estos comandos lo que hacen es: loguearnos al servicio de ECR, etiquetar la imagen con la nomenclatura que necesita el servicio, y por último subir la imagen al repositorio.

6. Una vez que tenemos la imagen en ECR, podemos probarla ejecutando docker run, con los siguientes parámetros:
```
docker run -it --rm \
  --env HOP_LOG_LEVEL=Basic \
  --env HOP_FILE_PATH='${PROJECT_HOME}/procesos/prueba_pipeline.hpl' \
  --env HOP_PROJECT_FOLDER=/home/hop/apache-hop \
  --env HOP_PROJECT_NAME=apache-hop \
  --env HOP_RUN_CONFIG=local \
  --env HOP_CUSTOM_ENTRYPOINT_EXTENSION_SHELL_FILE_PATH=/home/hop/clone-git-repo.sh \
  --env GIT_REPO_URI=https://github.com/datalytics-mejorcondatos/apache-hop.git \
  hop:2.3
```

Para más detalle de este ejemplo y de las variables de entorno que utiliza, visitar [esta documentación](https://hop.apache.org/tech-manual/latest/docker-container.html). 

7. Para automatizar la ejecución, podemos utilizar el servicio AWS Batch que nos permite ejecutar imagenes de docker, en este caso de Hop, en un entorno sin servidor. Para ello seguiremos los pasos de [este tutorial](https://docs.aws.amazon.com/batch/latest/userguide/Batch_GetStarted.html) teniendo en cuenta las siguientes consideraciones:
    - Utilizar Fargate como motor de orquestación, en particular instancias Spot.
    - En imagen completar con la URI cuando se hizo el push: *numero_de_cuenta*.dkr.ecr.*region_a_utilizar*.amazonaws.com/hop:2.3
    - En comando no es necesario ingresar ningún valor, ya que la imagen es la que se encarga de ejecutar Hop.
    - Utilizar 1 vCPU y 2 GB de memoria.
    - Agregar las mismas variables de entorno que en el punto anterior, para HOP_FILE_PATH borrar las comillas simples.
    - El contenedor tiene que tener IP pública asignada para poder descargar la imagen de ECR.
    
8. Si el trabajo ejecutó correctamente, en la pestaña de Registros veremos el log de Hop igual a la salida del comando docker del punto anterior.

9. Finalmente, podríamos invocar AWS Batch desde otro servicio, como puede ser Step Functions, utilizando la misma configuración de trabajo del punto anterior.

## Ejecución con archivo de entorno y drivers JDBC

Cuando configuramos [entornos](https://hop.apache.org/manual/latest/projects/index.html#_environments) en Hop para manejar de manera ordenada cuestiones como credenciales de conexión a bases de datos, Hop genera un archivo JSON.
Dado que estos tienen información sensible, lo ideal es utilizar servicios para administrarlos. En AWS utilizaremos [Secrets Manager](https://docs.aws.amazon.com/batch/latest/userguide/specifying-sensitive-data-secrets.html).

Para que podamos utilizar este secreto en AWS Batch, tenemos que hacer las siguientes modificaciones al paso a paso anterior:

1. Generar y subir una nueva imagen utilizando el archivo Dockerfile.entornos. Este archivo copia el script `clone-git-repo-and-secret.sh` que, además de clonar el repositorio indicado, vuelca el contenido del secret a un archivo. El secret está disponible en el contenedor como una variable de entorno.
2. Agregar las siguientes variables de entorno a la definición del trabajo:
    ```
    - HOP_ENVIRONMENT_NAME
    - HOP_ENVIRONMENT_CONFIG_FILE_NAME_PATHS=${PROJECT_HOME}/config/env-config.json
    ```
3. Agregar un secreto a la definición del trabajo:
    ```
    - CONFIG_FILE=arn:aws:secretsmanager:*region_a_utilizar*:*numero_de_cuenta*:secret:*id_del_secreto*
    ```
Por otro lado, si necesitamos drivers JDBC (generalmente serán archivos .jar) en nuestros pipelines, el Dockerfile.entornos contiene una instrucción que se encarga de copiarlos desde nuestro entorno local al contenedor.
Luego, en la definición del trabajo en AWS Batch, agregamos la variable de entorno:
    ```    
    - HOP_SHARED_JDBC_FOLDER=/home/hop/drivers
    ```
