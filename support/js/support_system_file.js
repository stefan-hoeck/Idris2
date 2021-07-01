const support_system_file_fs = require('fs')


function support_system_file_fileErrno(){
  const n = process.__lasterr===undefined?0:process.__lasterr.errno || 0
  if (process.platform == 'win32') {
    // TODO: Add the error codes for the other errors
    switch(n) {
      case -4058: return 2
      case -4075: return 4
      default: return -n
    }
  } else {
    switch(n){
      case -17: return 4
      default: return -n
    }
  }
}

// like `readLine` without the overhead of copying characters.
// returns int (success 0, failure -1) to align with the C counterpart.
function support_system_file_seekLine (file_ptr) {
  const LF = 0x0a
  const readBuf = Buffer.alloc(1)
  let lineEnd = file_ptr.buffer.indexOf(LF)
  while (lineEnd === -1) {
    const bytesRead = support_system_file_fs.readSync(file_ptr.fd, readBuf, 0, 1, null)
    if (bytesRead === 0) {
      file_ptr.eof = true
      file_ptr.buffer = Buffer.alloc(0)
      return 0
    }
    file_ptr.buffer = Buffer.concat([file_ptr.buffer, readBuf.slice(0, bytesRead)])
    lineEnd = file_ptr.buffer.indexOf(LF)
  }
  file_ptr.buffer = file_ptr.buffer.slice(lineEnd + 1)
  return 0
}

function support_system_file_readLine (file_ptr) {
  const LF = 0x0a
  const readBuf = Buffer.alloc(1)
  let lineEnd = file_ptr.buffer.indexOf(LF)
  while (lineEnd === -1) {
    const bytesRead = support_system_file_fs.readSync(file_ptr.fd, readBuf, 0, 1, null)
    if (bytesRead === 0) {
      file_ptr.eof = true
      const line = file_ptr.buffer.toString('utf-8')
      file_ptr.buffer = Buffer.alloc(0)
      return line
    }
    file_ptr.buffer = Buffer.concat([file_ptr.buffer, readBuf.slice(0, bytesRead)])
    lineEnd = file_ptr.buffer.indexOf(LF)
  }
  const line = file_ptr.buffer.slice(0, lineEnd + 1).toString('utf-8')
  file_ptr.buffer = file_ptr.buffer.slice(lineEnd + 1)
  return line
}

function support_system_file_getStr () {
  return support_system_file_readLine({ fd: 0, buffer: Buffer.alloc(0), name: '<stdin>', eof: false })
}

function support_system_file_openFile (n, m) {
  try {
    const fd = support_system_file_fs.openSync(n, m.replace('b', ''))
    return { fd: fd, buffer: Buffer.alloc(0), name: n, eof: false }
  } catch (e) {
    process.__lasterr = e
    return null
  }
}

function support_system_file_chmod (filename, mode) {
  try {
    support_system_file_fs.chmodSync(filename, mode)
    return 0
  } catch (e) {
    process.__lasterr = e
    return 1
  }
}

function support_system_file_readChars (len, file_ptr) {
  let ret = file_ptr.buffer
  if (ret.length >= len) {
    ret = ret.slice(0, len).toString('utf-8')
    file_ptr.buffer = file_ptr.buffer.slice(len)
  } else {
    const readBuf = Buffer.alloc(len - ret.length)
    const bytesRead = support_system_file_fs.readSync(file_ptr.fd, readBuf, 0, readBuf.length, null)
    ret = Buffer.concat([ret, readBuf.slice(0, bytesRead)])
    file_ptr.buffer = Buffer.alloc(0)
  }
  return ret.toString('utf-8')
}

function support_system_file_readChar (file_ptr) {
  if (file_ptr.buffer.length > 1) {
    const ret = file_ptr.buffer[0]
    file_ptr.buffer = file_ptr.buffer.slice(1)
  } else {
    const readBuf = Buffer.alloc(1)
    const bytesRead = support_system_file_fs.readSync(file_ptr.fd, readBuf, 0, 1, null)
    if (bytesRead == 0) {
      file_ptr.eof = true
      return -1
    }
    return readBuf[0]
  }
}
