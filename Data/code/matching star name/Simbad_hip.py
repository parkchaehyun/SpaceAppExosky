import pandas as pd
from astroquery.simbad import Simbad
import asyncio
from concurrent.futures import ThreadPoolExecutor
import time
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# SIMBAD에서 추가적인 필드 설정
Simbad.add_votable_fields('ids')

# CSV 파일 읽기
df_gaia = pd.read_csv('filtered_gaia_data_Earth.csv')
df_gaia['star_name'] = None

# source_id를 사용하여 SIMBAD에서 별의 이름을 조회하는 함수
def get_star_name(source_id, retries=3):
    """SIMBAD에서 별 이름을 조회하는 함수 (재시도 포함)"""
    for attempt in range(retries):
        try:
            result = Simbad.query_object(f"Gaia DR3 {source_id}")
            if result is not None:
                return result['MAIN_ID'][0]  # MAIN_ID 반환
            else:
                return None  # 조회되지 않으면 None 반환
        except Exception as e:
            logging.warning(f"Error with Gaia source_id {source_id} on attempt {attempt + 1}: {e}")
            time.sleep(1)  # 재시도 전에 잠시 대기
    return None  # 재시도 횟수를 초과하면 None 반환

# 비동기 방식으로 동기 함수를 실행하는 함수
async def fetch_all_star_names(max_workers=10, save_step=1000):
    """비동기 방식으로 SIMBAD에서 star_name을 조회"""
    star_names = []
    loop = asyncio.get_running_loop()
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        tasks = []
        for i, row in df_gaia.iterrows():
            if pd.isnull(row['star_name']):
                source_id = row['SOURCE_ID']
                # 동기 작업을 비동기 방식으로 실행
                tasks.append(loop.run_in_executor(pool, get_star_name, source_id))
            
            # 일정 간격으로 진행 상황 저장
            if i > 0 and i % save_step == 0:
                logging.info(f"Progress: {i}/{len(df_gaia)} rows processed. Saving progress...")
                df_gaia.to_csv('gaia_star_name_async_temp.csv', index=False)  # 중간 저장
            
        star_names = await asyncio.gather(*tasks)  # 모든 작업이 완료될 때까지 기다림
    return star_names

# 메인 함수
async def main():
    logging.info("Starting SIMBAD star name retrieval process...")
    star_names = await fetch_all_star_names(max_workers=10, save_step=1000)
    df_gaia['star_name'] = star_names
    df_gaia.to_csv('gaia_star_name_async.csv', index=False)
    logging.info("Process completed and saved as 'gaia_star_name_async.csv'")

# 비동기 코드 실행
asyncio.run(main())
