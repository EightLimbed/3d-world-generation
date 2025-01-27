using Godot;
using System;
using System.Collections.Generic;

public partial class MeshGenerator : Node
{
	bool[] transparency = { true, false, false, false, false, false, true, true };
	Vector2 texDiv = new Vector2(1.0f / 7.0f, 1.0f / 6.0f);
	List<Vector3> vertices = new List<Vector3>();
	List<int> indices = new List<int>();
	List<Vector2> uvs = new List<Vector2>();
	int faceCount = 0;
	int chunkSize;
	int[] blocks;

	public Godot.Collections.Array CreateMesh(int[] blockArray, int size)
	{
		// Initialize variables
		vertices.Clear();
		indices.Clear();
		uvs.Clear();
		faceCount = 0;
		chunkSize = size;
		blocks = blockArray;

		// Generate blocks with faces culled
		for (int x = 0; x < chunkSize; x++)
		{
			for (int y = 0; y < chunkSize; y++)
			{
				for (int z = 0; z < chunkSize; z++)
				{
					int index = GetIndex(x, y, z);
					int blockType = blocks[index];
					if (blockType != 0) // Skip empty blocks
					{
						// Precompute face visibility
						bool[] visibleFaces = GetVisibleFaces(new Vector3(x, y, z), blockType);

						// Add block with visible faces only
						CreateBlock(new Vector3(x, y, z), blockType, visibleFaces);
					}
				}
			}
		}

		// Return the mesh data if there are any faces
		if (faceCount > 0)
		{
			return new Godot.Collections.Array { vertices.ToArray(), indices.ToArray(), uvs.ToArray() };
		}
		else
		{
			return new Godot.Collections.Array();
		}
	}

	void CreateBlock(Vector3 pos, int type, bool[] visibleFaces)
	{
		// Top face
		if (visibleFaces[0])
		{
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(0.5f, 0.5f, 0.5f));
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, 0.5f));
			UpdateIndices();
			AddUv(type - 1, 0);
		}

		// Bottom face
		if (visibleFaces[1])
		{
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, 0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, 0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, -0.5f));
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, -0.5f));
			UpdateIndices();
			AddUv(type - 1, 1);
		}

		// Right face
		if (visibleFaces[2])
		{
			vertices.Add(pos + new Vector3(0.5f, 0.5f, 0.5f));
			vertices.Add(pos + new Vector3(0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, -0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, 0.5f));
			UpdateIndices();
			AddUv(type - 1, 2);
		}

		// Left face
		if (visibleFaces[3])
		{
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, 0.5f));
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, 0.5f));
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, -0.5f));
			UpdateIndices();
			AddUv(type - 1, 3);
		}

		// Front face
		if (visibleFaces[4])
		{
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, 0.5f));
			vertices.Add(pos + new Vector3(0.5f, 0.5f, 0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, 0.5f));
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, 0.5f));
			UpdateIndices();
			AddUv(type - 1, 4);
		}

		// Back face
		if (visibleFaces[5])
		{
			vertices.Add(pos + new Vector3(0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(-0.5f, 0.5f, -0.5f));
			vertices.Add(pos + new Vector3(-0.5f, -0.5f, -0.5f));
			vertices.Add(pos + new Vector3(0.5f, -0.5f, -0.5f));
			UpdateIndices();
			AddUv(type - 1, 5);
		}
	}

	bool[] GetVisibleFaces(Vector3 pos, int type)
	{
		bool[] visibleFaces = new bool[6];
		Vector3[] directions = {
			new Vector3(0, 1, 0),   // Top
			new Vector3(0, -1, 0),  // Bottom
			new Vector3(1, 0, 0),   // Right
			new Vector3(-1, 0, 0),  // Left
			new Vector3(0, 0, 1),   // Front
			new Vector3(0, 0, -1)   // Back
		};

		for (int i = 0; i < 6; i++)
		{
			visibleFaces[i] = NotTransparent(pos + directions[i], type);
		}

		return visibleFaces;
	}

	bool NotTransparent(Vector3 pos, int type)
	{
		int x = (int)pos.X;
		int y = (int)pos.Y;
		int z = (int)pos.Z;

		if (x < 0 || y < 0 || z < 0 || x >= chunkSize || y >= chunkSize || z >= chunkSize)
		{
			return true;
		}

		int neighborIndex = GetIndex(x, y, z);
		int neighborType = blocks[neighborIndex];

		if (type == neighborType)
		{
			return false;
		}

		return transparency[neighborType];
	}

	int GetIndex(int x, int y, int z)
	{
		return z + chunkSize * (y + chunkSize * x);
	}

	void AddUv(int x, int y)
	{
		uvs.Add(new Vector2(texDiv.X * x, texDiv.Y * y));
		uvs.Add(new Vector2(texDiv.X * x + texDiv.X, texDiv.Y * y));
		uvs.Add(new Vector2(texDiv.X * x + texDiv.X, texDiv.Y * y + texDiv.Y));
		uvs.Add(new Vector2(texDiv.X * x, texDiv.Y * y + texDiv.Y));
	}

	void UpdateIndices()
	{
		indices.Add(faceCount * 4 + 0);
		indices.Add(faceCount * 4 + 1);
		indices.Add(faceCount * 4 + 2);
		indices.Add(faceCount * 4 + 0);
		indices.Add(faceCount * 4 + 2);
		indices.Add(faceCount * 4 + 3);
		faceCount += 1;
	}
}
