/* @flow */

import mapStateToProps from '../map-state-to-props'

const template = {
  ...require('../../../../api/canvas-api/__templates__/course'),
  ...require('../../../../api/canvas-api/__templates__/tab'),
  ...require('../../../../redux/__templates__/app-state'),
}

test('mapStateToProps returns the correct props', () => {
  const course = template.course({ id: 1 })
  const tabs = { tabs: [template.tab()] }
  const state = template.appState({
    entities: {
      courses: {
        '1': {
          course: course,
          color: '#fff',
          tabs: tabs,
        },
      },
    },
    favoriteCourses: {
      courseRefs: ['1'],
    },
  })
  const expected = {
    course,
    ...tabs,
    color: '#fff',
  }

  const props = mapStateToProps(state, { courseID: '1' })

  expect(props).toEqual(expected)
})

test('mapStateToProps throws without course', () => {
  const state: { [string]: any } = {
    entities: {
    },
    favoriteCourses: {},
  }

  expect(() => {
    mapStateToProps(state, { courseID: '1' })
  }).toThrow()
})
