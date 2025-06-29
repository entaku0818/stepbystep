import * as logger from "firebase-functions/logger";

/**
 * タスクを5つのステップに分割する（モック実装）
 * 後でOpenAI APIに差し替え予定
 */
export async function splitTaskIntoSteps(task: string): Promise<string[]> {
  logger.info(`Splitting task: ${task}`);
  
  // 簡単な遅延をシミュレート（実際のAPI呼び出しの代わり）
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  const steps = [
    `${task}の準備をする`,
    `${task}の計画を立てる`,
    `${task}を実行する`,
    `${task}の確認をする`,
    `${task}を完了させる`
  ];
  
  logger.info(`Generated steps:`, steps);
  
  return steps;
}

/**
 * 将来のOpenAI API実装の準備
 * TODO: OpenAI APIキー設定後に実装
 */
export async function splitTaskWithOpenAI(task: string): Promise<string[]> {
  // OpenAI API実装予定地
  throw new Error("OpenAI API integration not implemented yet");
}