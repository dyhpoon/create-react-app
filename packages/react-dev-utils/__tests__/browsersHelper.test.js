'use strict';

const path = require('path')
const { defaultBrowsers, checkBrowsers, printBrowsers } = require('../browsersHelper')


describe('check browser', () => {
  it('check browser', (done) => {
    printBrowsers(path.join(__dirname, '../fixture'))
      .then(done)
  })

  it('check default', () => {
    expect(defaultBrowsers).toMatchObject({
      "development": [
        "last 2 chrome versions",
        "last 2 firefox versions",
        "last 2 edge versions"
      ],
      "production": [
        ">1%",
        "last 4 versions",
        "Firefox ESR",
        "not ie < 11"
      ]
    })
  })
})