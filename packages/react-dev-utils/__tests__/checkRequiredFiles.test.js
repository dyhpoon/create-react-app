'use strict';

const checkRequiredFiles = require('../checkRequiredFiles')
const path = require('path')

describe('check required files', () => {
  it('files exist', () => {
    const file = path.join(__dirname, '../fixture/package.json')
    const isExisted = checkRequiredFiles([file])
    expect(isExisted).toBeTruthy()
  })

  it('file not exist', () => {
    const file = path.join(__dirname, '../fixture/no-exist')
    const isExisted = checkRequiredFiles([file])
    expect(isExisted).toBeFalsy()
  })
})
