/* eslint-disable */
import { readFileSync } from 'fs';

// Reading the SWC compilation config for the spec files
const swcJestConfig = JSON.parse(
  readFileSync(`${__dirname}/.spec.swcrc`, 'utf-8')
);

// Disable .swcrc look-up by SWC core because we're passing in swcJestConfig ourselves
swcJestConfig.swcrc = false;

export default {
  displayName: 'api-gateway',
  preset: '../jest.preset.js',
  testEnvironment: 'node',
  transform: {
    '^.+\\.[tj]s$': ['@swc/jest', swcJestConfig],
  },
  moduleFileExtensions: ['ts', 'js', 'html'],
  coverageDirectory: 'test-output/jest/coverage',
  testPathIgnorePatterns: [
    '<rootDir>/.*-e2e/.*',
    '<rootDir>/auth/.*',
    '<rootDir>/analysis/.*',
    '<rootDir>/citation/.*',
    '<rootDir>/ocr-wrapper/.*'
  ],
  testMatch: [
    '<rootDir>/src/**/*.(spec|test).[jt]s?(x)'
  ]
};
