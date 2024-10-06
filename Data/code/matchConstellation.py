import csv
import json

# HIP_K2-18_mag6.json 파일을 읽어 source_id를 키로 하는 딕셔너리 생성
with open('../server/data/K2-18/HIP_K2-18_mag6.json', 'r') as json_file:
    star_data_list = json.load(json_file)
    star_data_dict = {star['source_id']: star for star in star_data_list}

# constellationship.csv 파일을 읽고 새로운 데이터 생성
with open('../server/data/constellationship.csv', 'r', encoding='utf-8') as csv_file:
    reader = csv.reader(csv_file)
    headers = next(reader)  # 헤더 추출

    # 결과를 저장할 리스트 초기화
    result_data = []

    for row in reader:
        constellation_data = {}
        constellation_data['Constellation'] = row[0]
        constellation_data['Number_of_Stars'] = int(row[1])

        # 라인 데이터 추출
        line_data = row[2:]

        # 라인별로 x, y, z 좌표 추가
        for i in range(0, len(line_data), 2):
            line_index = i // 2 + 1
            start_id = int(line_data[i]) if line_data[i] else None
            end_id = int(line_data[i+1]) if line_data[i+1] else None

            if start_id and end_id:
                # 시작점 좌표
                start_star = star_data_dict.get(start_id)
                if start_star:
                    constellation_data[f'line{line_index}_start_x'] = start_star['x_normalized']
                    constellation_data[f'line{line_index}_start_y'] = start_star['y_normalized']
                    constellation_data[f'line{line_index}_start_z'] = start_star['z_normalized']
                else:
                    constellation_data[f'line{line_index}_start_x'] = None
                    constellation_data[f'line{line_index}_start_y'] = None
                    constellation_data[f'line{line_index}_start_z'] = None

                # 끝점 좌표
                end_star = star_data_dict.get(end_id)
                if end_star:
                    constellation_data[f'line{line_index}_end_x'] = end_star['x_normalized']
                    constellation_data[f'line{line_index}_end_y'] = end_star['y_normalized']
                    constellation_data[f'line{line_index}_end_z'] = end_star['z_normalized']
                else:
                    constellation_data[f'line{line_index}_end_x'] = None
                    constellation_data[f'line{line_index}_end_y'] = None
                    constellation_data[f'line{line_index}_end_z'] = None

        result_data.append(constellation_data)

# 결과를 JSON 파일로 저장
with open('K2-18_constellationship_xyz.json', 'w', encoding='utf-8') as json_output:
    json.dump(result_data, json_output, ensure_ascii=False, indent=4)

print("작업이 완료되었습니다. 'constellationship_xyz.json' 파일이 생성되었습니다.")
