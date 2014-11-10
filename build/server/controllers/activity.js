// Generated by CoffeeScript 1.7.1
var Contact, ContactActivity, Promise;

Contact = require('../models/contact');

Promise = require('bluebird');

ContactActivity = {
  search: function(data, cb) {
    var onData, params;
    onData = function(err, result) {
      var pictures;
      if (err != null) {
        return cb(err, result);
      } else {
        pictures = [];
        result.forEach(function(contact) {
          var p;
          p = new Promise(function(resolve, reject) {
            var bufs, stream, _ref;
            if ((_ref = contact._attachments) != null ? _ref.picture : void 0) {
              stream = contact.getFile('picture', function(err) {
                if (err != null) {
                  return console.log(err);
                }
              });
              bufs = [];
              stream.on('data', function(d) {
                return bufs.push(d);
              });
              return stream.on('end', function() {
                var avatar, buf;
                buf = Buffer.concat(bufs);
                avatar = "data:image/jpeg;base64," + buf.toString('base64');
                contact.datapoints.push({
                  name: 'avatar',
                  value: avatar
                });
                return resolve(contact);
              });
            } else {
              return resolve(contact);
            }
          });
          return pictures.push(p);
        });
        return Promise.all(pictures).then(function(res) {
          return cb(err, res);
        });
      }
    };
    if (data.query != null) {
      params = {
        startkey: data.query,
        endkey: data.query + "\uFFFF"
      };
      return Contact.request('byName', params, onData);
    } else {
      return Contact.request('all', onData);
    }
  },
  create: function(data, cb) {
    var key, _ref;
    if (((_ref = data.contact) != null ? _ref.address : void 0) != null) {
      key = data.contact.address;
      return Contact.request('byEmail', {
        key: key
      }, function(err, contacts) {
        var contact;
        if (err) {
          return cb(err, null);
        } else {
          if (contacts.length === 0) {
            contact = {
              fn: data.contact.name,
              datapoints: [
                {
                  name: "email",
                  value: data.contact.address
                }
              ]
            };
            return Contact.create(contact, function(err, result) {
              if (err != null) {
                return cb(err, result);
              } else {
                return Contact.request('byEmail', {
                  key: key
                }, cb);
              }
            });
          } else {
            return cb(null, contacts);
          }
        }
      });
    } else {
      return cb("BAD FORMAT", null);
    }
  },
  "delete": function(data, cb) {
    return Contact.find(data.id, function(err, contact) {
      if ((err != null) || (contact == null)) {
        return cb(err);
      } else {
        return contact.destroy(cb);
      }
    });
  }
};

module.exports.create = function(req, res, next) {
  var activity;
  activity = req.body;
  switch (activity.data.type) {
    case 'contact':
      if (ContactActivity[activity.name] != null) {
        return ContactActivity[activity.name](activity.data, function(err, result) {
          if (err != null) {
            return res.send(400, {
              name: err,
              error: true
            });
          } else {
            return res.send(200, {
              result: result
            });
          }
        });
      } else {
        return res.send(400, {
          name: "Unknown activity name",
          error: true
        });
      }
      break;
    default:
      return res.send(400, {
        name: "Unknown activity data type",
        error: true
      });
  }
};
