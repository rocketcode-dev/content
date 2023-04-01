const myusers = {
  thomas: {
    password: 'super-secret-password',
    roles: 'role1,role2,role3'
  }
};

function authAccepted(user) {
  context.message.header.set('X-Authenticated-User', user);
  context.message.header.set('X-Authenticated-Roles', myusers[user].roles);
  return true;
}

function authRequired() {
  context.message.statusCode = 401;
  context.message.header.set('WWW-Authenticate', 'Basic realm="basic-auth-demo"');
  return false;
}

function authFlow() {

  let authHeader = context.request.header.get('Authorization');
  if (!authHeader) {
    return authRequired();
  }

  let [authtype, userpass] = authHeader.split(' ');
  if (authtype.toUpperCase() !== 'BASIC') {
    return authRequired();
  }

  let [user, pass] = new Buffer(userpass, 'base64').toString()
    .replace(/\n/,'').split(':');
  return doAuth(user, pass);

}

function doAuth(user, pass) {
  if (myusers[user] === undefined) {
    return authRequired();
  } else if (myusers[user].password === pass) {
    return authAccepted(user);
  } else {
    return authRequired();
  }
}

authFlow();
