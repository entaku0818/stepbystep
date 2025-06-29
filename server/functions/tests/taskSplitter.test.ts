import {splitTaskIntoSteps} from '../src/taskSplitter';

describe('TaskSplitter', () => {
  describe('splitTaskIntoSteps', () => {
    it('should split a task into 5 steps', async () => {
      const task = '部屋の掃除をする';
      const steps = await splitTaskIntoSteps(task);
      
      expect(steps).toHaveLength(5);
      expect(steps[0]).toBe('部屋の掃除をするの準備をする');
      expect(steps[1]).toBe('部屋の掃除をするの計画を立てる');
      expect(steps[2]).toBe('部屋の掃除をするを実行する');
      expect(steps[3]).toBe('部屋の掃除をするの確認をする');
      expect(steps[4]).toBe('部屋の掃除をするを完了させる');
    });
    
    it('should handle different task types', async () => {
      const task = 'プレゼン資料作成';
      const steps = await splitTaskIntoSteps(task);
      
      expect(steps).toHaveLength(5);
      expect(steps).toEqual([
        'プレゼン資料作成の準備をする',
        'プレゼン資料作成の計画を立てる',
        'プレゼン資料作成を実行する',
        'プレゼン資料作成の確認をする',
        'プレゼン資料作成を完了させる'
      ]);
    });
    
    it('should handle short tasks', async () => {
      const task = '買い物';
      const steps = await splitTaskIntoSteps(task);
      
      expect(steps).toHaveLength(5);
      expect(steps[0]).toContain('買い物');
    });
    
    it('should complete within reasonable time', async () => {
      const start = Date.now();
      const task = 'テストタスク';
      
      await splitTaskIntoSteps(task);
      
      const duration = Date.now() - start;
      expect(duration).toBeLessThan(2000); // 2秒以内
    });
  });
});