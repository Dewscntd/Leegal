import 'reflect-metadata';
import { IsEnum, IsNumber, IsOptional, IsString, IsUrl, validateSync } from 'class-validator';
import { Transform, plainToClass } from 'class-transformer';

/**
 * Environment types
 */
export enum Environment {
  DEVELOPMENT = 'development',
  STAGING = 'staging',
  PRODUCTION = 'production',
  TEST = 'test',
}

/**
 * Log levels
 */
export enum LogLevel {
  FATAL = 'fatal',
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug',
  TRACE = 'trace',
}

/**
 * Base environment configuration schema
 */
export class BaseEnvironmentConfig {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.DEVELOPMENT;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  PORT: number = 3000;

  @IsEnum(LogLevel)
  @IsOptional()
  LOG_LEVEL: LogLevel = LogLevel.INFO;

  @IsString()
  @IsOptional()
  SERVICE_NAME?: string;

  @IsString()
  @IsOptional()
  SERVICE_VERSION?: string;
}

/**
 * Database configuration schema
 */
export class DatabaseConfig {
  @IsUrl({ require_tld: false })
  @IsOptional()
  DATABASE_URL?: string;

  @IsString()
  @IsOptional()
  DB_HOST?: string;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  DB_PORT?: number;

  @IsString()
  @IsOptional()
  DB_NAME?: string;

  @IsString()
  @IsOptional()
  DB_USER?: string;

  @IsString()
  @IsOptional()
  DB_PASSWORD?: string;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  DB_POOL_MIN?: number = 2;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  DB_POOL_MAX?: number = 10;
}

/**
 * Redis configuration schema
 */
export class RedisConfig {
  @IsUrl({ require_tld: false })
  @IsOptional()
  REDIS_URL?: string;

  @IsString()
  @IsOptional()
  REDIS_HOST?: string;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  REDIS_PORT?: number;

  @IsString()
  @IsOptional()
  REDIS_PASSWORD?: string;

  @IsNumber()
  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  REDIS_DB?: number = 0;
}

/**
 * JWT configuration schema
 */
export class JwtConfig {
  @IsString()
  JWT_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_EXPIRES_IN?: string = '1h';

  @IsString()
  @IsOptional()
  JWT_REFRESH_SECRET?: string;

  @IsString()
  @IsOptional()
  JWT_REFRESH_EXPIRES_IN?: string = '7d';
}

/**
 * Complete environment configuration schema
 */
export class EnvironmentConfig extends BaseEnvironmentConfig {
  // Database configuration
  @IsOptional()
  database?: DatabaseConfig;

  // Redis configuration
  @IsOptional()
  redis?: RedisConfig;

  // JWT configuration
  @IsOptional()
  jwt?: JwtConfig;
}

/**
 * Validate environment variables against a schema
 * @param config Configuration class constructor
 * @param envVars Environment variables object (defaults to process.env)
 * @returns Validated and transformed configuration object
 * @throws Error if validation fails
 */
export function validateEnvironment<T extends object>(
  config: new () => T,
  envVars: Record<string, unknown> = process.env
): T {
  const validatedConfig = plainToClass(config, envVars, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
    whitelist: true,
    forbidNonWhitelisted: true,
  });

  if (errors.length > 0) {
    const errorMessages = errors
      .map((error) => {
        const constraints = error.constraints;
        return constraints
          ? Object.values(constraints).join(', ')
          : `Invalid value for ${error.property}`;
      })
      .join('; ');

    throw new Error(`Environment validation failed: ${errorMessages}`);
  }

  return validatedConfig;
}

/**
 * Create a validation function for a specific configuration schema
 * @param config Configuration class constructor
 * @returns Validation function
 */
export function createEnvironmentValidator<T extends object>(
  config: new () => T
): (envVars?: Record<string, unknown>) => T {
  return (envVars?: Record<string, unknown>) =>
    validateEnvironment(config, envVars);
}

/**
 * Default environment validator using BaseEnvironmentConfig
 */
export const validateBaseEnvironment = createEnvironmentValidator(BaseEnvironmentConfig);

/**
 * Complete environment validator using EnvironmentConfig
 */
export const validateCompleteEnvironment = createEnvironmentValidator(EnvironmentConfig);
