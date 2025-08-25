import * as functions from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import {splitTaskIntoSteps} from "./taskSplitter";

// Secret Manager からAPIキーを取得
const apiKeySecret = defineSecret("STEPBYSTEP_API_KEY");

// フォールバック用のデフォルトキー (一時的にコメントアウト)
// const DEFAULT_API_KEY = "stepbystep-dev-key-2024";

export const splitTask = functions
  .runWith({
    secrets: [apiKeySecret],
  })
  .https.onRequest(async (request, response) => {
    console.log("splitTask called");

    try {
      // CORS headers
      response.set("Access-Control-Allow-Origin", "*");
      response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      response.set(
        "Access-Control-Allow-Headers",
        "Content-Type, Authorization, X-API-Key"
      );

      // Handle preflight OPTIONS request
      if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
      }

      // Only allow POST requests
      if (request.method !== "POST") {
        response.status(405).json({error: "Method not allowed"});
        return;
      }

      // API キー認証 (デバッグ用に一時的にハードコード)
      const validApiKey = "***REMOVED***";
      const clientApiKey = request.headers["x-api-key"] ||
        request.headers["authorization"];

      console.log("Expected API key:", validApiKey);
      console.log("Received API key:", clientApiKey);
      console.log("API keys match:", clientApiKey === validApiKey);

      if (!clientApiKey || clientApiKey !== validApiKey) {
        console.log("Invalid or missing API key:", clientApiKey);
        response.status(401).json({
          error: "Unauthorized",
          message: "Valid API key is required",
        });
        return;
      }

      const {task} = request.body;

      if (!task || typeof task !== "string") {
        response.status(400).json({
          error: "Task is required and must be a string",
        });
        return;
      }

      if (task.length < 5 || task.length > 100) {
        response.status(400).json({
          error: "Task must be between 5 and 100 characters",
        });
        return;
      }

      const steps = await splitTaskIntoSteps(task);

      response.json({
        success: true,
        steps: steps,
        originalTask: task,
      });
    } catch (error) {
      console.error("Error in splitTask:", error);
      response.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ?
          error.message : "Unknown error",
      });
    }
  });
