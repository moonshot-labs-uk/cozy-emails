// Generated by CoffeeScript 1.9.3
var Message, async, log, markAllMessagesAsIgnored, patchOneAccount, ramStore, safeLoop;

Message = require('../models/message');

safeLoop = require('../utils/safeloop');

async = require('async');

ramStore = require('../models/store_account_and_boxes');

log = require('../utils/logging')({
  prefix: 'patch:ignored'
});

exports.patchAllAccounts = function(callback) {
  var accounts;
  accounts = ramStore.getAllAccounts();
  return async.eachSeries(accounts, patchOneAccount, callback);
};

patchOneAccount = function(account, callback) {
  var boxes;
  log.debug("applyPatchIgnored, already = ", account.patchIgnored);
  if (account.patchIgnored) {
    return callback(null);
  }
  boxes = [];
  if (account.trashMailbox) {
    boxes.push(account.trashMailbox);
  }
  if (account.junkMailbox) {
    boxes.push(account.junkMailbox);
  }
  log.debug("applyPatchIgnored", boxes);
  return safeLoop(boxes, markAllMessagesAsIgnored, function(errors) {
    if (errors.length) {
      log.debug("applyPatchIgnored:fail", account.id);
      return callback(null);
    } else {
      log.debug("applyPatchIgnored:success", account.id);
      return account.updateAttributes({
        patchIgnored: true
      }, callback);
    }
  });
};

markAllMessagesAsIgnored = function(boxID, callback) {
  var changes, markIgnored;
  changes = {
    ignoreInCount: true
  };
  markIgnored = function(id, next) {
    return Message.updateAttributes(id, changes, next);
  };
  return Message.rawRequest('byMailboxRequest', {
    startkey: ['uid', boxID, 0],
    endkey: ['uid', boxID, 'a'],
    reduce: false
  }, function(err, rows) {
    var ids;
    if (err) {
      return callback(err);
    }
    ids = rows != null ? rows.map(function(row) {
      return row.id;
    }) : void 0;
    return safeLoop(ids, markIgnored, function(errors) {
      var i, len;
      for (i = 0, len = errors.length; i < len; i++) {
        err = errors[i];
        log.warn("error marking msg ignored", err);
      }
      return callback(errors[0]);
    });
  });
};
