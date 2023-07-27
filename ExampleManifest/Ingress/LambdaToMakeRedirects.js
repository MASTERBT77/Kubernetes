// En lugar de leer el archivo de redirección redirects.json para cada invocación del controlador Lambda, podríamos hacerlo solo una vez al inicio. 
// Lambda conserva la instancia global, por lo que las redirecciones se almacenarán en la memoria en invocaciones posteriores, evitando la necesidad de 
// ir al S3 cada vez que se invoca el controlador.
// Trata de reducir el uso de expresiones regulares en la medida de lo posible. Son costosas en términos de rendimiento. Si los patrones son simples, 
// considera reemplazarlos con otros métodos de string.
// Manejar adecuadamente los errores para poder rastrear problemas en caso de que surjan.

const aws = require('aws-sdk');
const s3 = new aws.S3({ region: 'us-east-1' });
const s3Params = {
  Bucket: 'poc-grupo',
  Key: 'redirects.json',
};

let redirects;

async function fetchRedirections() {
  if (!redirects) {
    const response = await s3.getObject(s3Params).promise();
    redirects = JSON.parse(response.Body.toString('utf-8')).map(
      ({ source, destination, redirectCode, redirectDescription }) => ({
        source: new RegExp(source),
        destination,
        redirectCode,
        redirectDescription
      })
    );
  }
  return redirects;
}

exports.handler = async event => {
  const request = event.Records[0].cf.request;
 
  try {
    const redirects = await fetchRedirections();
 
    for (const { source, destination, redirectCode, redirectDescription } of redirects) {
      if (source.test(request.uri)) {
        return {
          status: redirectCode,
          statusDescription: redirectDescription,
          headers: {
            location: [{ value: destination }],
          },
        };
      }
    }
    
    return request;
    
  } catch (error) {
    console.error(`Error while handling request: ${error.message}`);
    return request;
  }
};


----

const aws = require('aws-sdk');
const s3 = new aws.S3({ region: 'us-east-1' });
const s3Params = {
  Bucket: 'poc-grupo',
  Key: 'redirects.json',
};
 
async function fetchRedirections() {
  const response = await s3.getObject(s3Params).promise();
  return JSON.parse(response.Body.toString('utf-8')).map(
    ({ source, destination, redirectCode, redirectDescription }) => ({
      source: new RegExp(source),
      destination,
      redirectCode,
      redirectDescription
    })
  );
}
 
exports.handler = async event => {
  const request = event.Records[0].cf.request;
 
  try {
    const redirects = await fetchRedirections();
 
    for (const { source, destination, redirectCode, redirectDescription } of redirects) {
      if (source.test(request.uri)) {
        return {
          status: redirectCode,
          statusDescription: redirectDescription,
          headers: {
            location: [{ value: destination }],
          },
        };
      }
    }
    
    return request;
    
  } catch (_error) {
    return request;
  }
};