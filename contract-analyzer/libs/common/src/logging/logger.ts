const pino = require('pino');

type PinoLogger = any;

/**
 * Logger configuration interface
 */
export interface LoggerConfig {
  level?: string;
  prettyPrint?: boolean;
  service?: string;
}

/**
 * Default logger configuration
 */
const defaultConfig: LoggerConfig = {
  level: process.env.LOG_LEVEL || 'info',
  prettyPrint: process.env.NODE_ENV !== 'production',
  service: process.env.SERVICE_NAME || 'contract-analyzer',
};

/**
 * Create a pino logger instance with consistent configuration
 * @param config Optional logger configuration
 * @returns Configured pino logger instance
 */
export function createLogger(config: LoggerConfig = {}): PinoLogger {
  const finalConfig = { ...defaultConfig, ...config };

  const pinoConfig: any = {
    level: finalConfig.level,
    base: {
      service: finalConfig.service,
      pid: process.pid,
    },
    timestamp: () => `,"time":"${new Date().toISOString()}"`,
  };

  // Add pretty printing for development
  if (finalConfig.prettyPrint) {
    return pino({
      ...pinoConfig,
      transport: {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      },
    });
  }

  return pino(pinoConfig);
}

/**
 * Default logger instance
 */
export const logger = createLogger();

/**
 * Logger utility class with common logging patterns
 */
export class Logger {
  private logger: PinoLogger;

  constructor(config: LoggerConfig = {}) {
    this.logger = createLogger(config);
  }

  /**
   * Create a child logger with additional context
   */
  child(bindings: Record<string, unknown>): Logger {
    const childLogger = new Logger();
    childLogger.logger = this.logger.child(bindings);
    return childLogger;
  }

  /**
   * Log debug message
   */
  debug(message: string, meta?: Record<string, unknown>): void {
    this.logger.debug(meta, message);
  }

  /**
   * Log info message
   */
  info(message: string, meta?: Record<string, unknown>): void {
    this.logger.info(meta, message);
  }

  /**
   * Log warning message
   */
  warn(message: string, meta?: Record<string, unknown>): void {
    this.logger.warn(meta, message);
  }

  /**
   * Log error message
   */
  error(message: string, error?: Error, meta?: Record<string, unknown>): void {
    const errorMeta = error
      ? {
          ...meta,
          error: {
            message: error.message,
            stack: error.stack,
            name: error.name,
          },
        }
      : meta;

    this.logger.error(errorMeta, message);
  }

  /**
   * Log fatal message
   */
  fatal(message: string, error?: Error, meta?: Record<string, unknown>): void {
    const errorMeta = error
      ? {
          ...meta,
          error: {
            message: error.message,
            stack: error.stack,
            name: error.name,
          },
        }
      : meta;

    this.logger.fatal(errorMeta, message);
  }

  /**
   * Get the underlying pino logger instance
   */
  getPinoLogger(): PinoLogger {
    return this.logger;
  }
}

/**
 * Default logger instance
 */
export const defaultLogger = new Logger();
