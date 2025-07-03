import * as logger from "firebase-functions/logger";
import {GoogleGenerativeAI} from "@google/generative-ai";

// Gemini API設定
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");

/**
 * タスクを5つのステップに分割する（Gemini API実装）
 * @param {string} task - 分割するタスク
 * @return {Promise<string[]>} 5つのステップ配列
 */
export async function splitTaskIntoSteps(task: string): Promise<string[]> {
  logger.info(`Splitting task: ${task}`);

  // 基本的なバリデーション
  if (!task || task.trim().length === 0) {
    throw new Error("タスクが空です");
  }

  if (task.length < 5) {
    throw new Error("タスクは5文字以上で入力してください");
  }

  if (task.length > 100) {
    throw new Error("タスクは100文字以内で入力してください");
  }

  // 本番環境でAPIキーが設定されていない場合はMockモードにフォールバック
  if (!process.env.GEMINI_API_KEY) {
    logger.warn("GEMINI_API_KEY not set, using mock implementation");
    return splitTaskIntoStepsMock(task);
  }

  try {
    // Gemini APIを使用してタスク分割
    const model = genAI.getGenerativeModel({model: "gemini-1.5-flash"});

    const prompt = `
以下のタスクを、具体的で実行可能な5つのステップに分割してください。
各ステップは短く、明確で、順番に実行できるものにしてください。

タスク: ${task}

要件:
- 必ず5つのステップにしてください
- 各ステップは50文字以内で簡潔に
- 実際に行動できる具体的な内容にしてください
- 順序立てて実行できるようにしてください
- 日本語で出力してください

出力形式:
1つのステップを1行で、5行のリストとして出力してください。
番号や記号は付けず、ステップの内容のみを出力してください。

例:
材料を準備する
レシピを確認する
調理を開始する
味を調整する
完成と片付け
`;

    logger.info("Calling Gemini API with prompt");
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    logger.info("Gemini API response:", text);

    // レスポンスを行ごとに分割してステップを抽出
    const steps = text.trim()
      .split("\n")
      .map((step) => step.trim())
      .filter((step) => step.length > 0)
      .slice(0, 5); // 念のため5つに制限

    // 5つのステップが取得できない場合はエラー
    if (steps.length !== 5) {
      logger.error("Gemini API returned incorrect number of steps:", steps);
      throw new Error("AIからの応答が正しい形式ではありません");
    }

    logger.info("Generated steps:", steps);
    return steps;
  } catch (error) {
    logger.error("Gemini API error:", error);

    // API エラーの場合はMockモードにフォールバック
    logger.warn("Falling back to mock implementation due to API error");
    return splitTaskIntoStepsMock(task);
  }
}

/**
 * Mock実装（フォールバック用）
 * @param {string} task - 分割するタスク
 * @return {Promise<string[]>} 5つのステップ配列
 */
async function splitTaskIntoStepsMock(task: string): Promise<string[]> {
  logger.info("Using mock implementation for task splitting");

  // Mock データ生成
  const steps = [
    `${task}の準備をする`,
    `${task}の計画を立てる`,
    `${task}を実行する`,
    `${task}の確認をする`,
    `${task}を完了させる`,
  ];

  // 非同期処理をシミュレート
  await new Promise((resolve) => setTimeout(resolve, 500));

  logger.info("Generated mock steps:", steps);
  return steps;
}

/**
 * 将来の拡張用（OpenAI API等）
 * @param {string} task - 分割するタスク（現在未使用）
 * @return {Promise<string[]>} ステップ配列
 */
export async function splitTaskWithOpenAI(task: string): Promise<string[]> {
  // OpenAI API実装予定地
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  throw new Error("OpenAI API integration not implemented yet");
}
