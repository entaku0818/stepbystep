import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {splitTaskIntoSteps} from "./taskSplitter";

export const splitTask = onRequest(
  {cors: true}, 
  async (request, response) => {
    logger.info("splitTask called", {structuredData: true});
    
    try {
      // CORS headers
      response.set("Access-Control-Allow-Origin", "*");
      response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      
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
      
      const {task} = request.body;
      
      if (!task || typeof task !== "string") {
        response.status(400).json({error: "Task is required and must be a string"});
        return;
      }
      
      if (task.length < 5 || task.length > 100) {
        response.status(400).json({error: "Task must be between 5 and 100 characters"});
        return;
      }
      
      const steps = await splitTaskIntoSteps(task);
      
      response.json({
        success: true,
        steps: steps,
        originalTask: task
      });
      
    } catch (error) {
      logger.error("Error in splitTask:", error);
      response.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      });
    }
  }
);
